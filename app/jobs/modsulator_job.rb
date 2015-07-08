require 'nokogiri'

# This class defines a Delayed Job task that is started when the user uploads a bulk metadata file for
# an APO.
class ModsulatorJob < ActiveJob::Base
  queue_as :default

  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = "%Y-%m-%d %H:%M%P"

  # This method is called by the caller running perform_later(), so we're using ActiveJob with Delayed Job as a backend.
  # The method does all the work of converting any input spreadsheets to XML, writing a log file as it goes along.
  #
  # @param  [String]  uploaded_filename  The full path to the temporary uploaded file. Will be deleted upon completion.
  # @param  [String]  output_directory   Where to store output (log, generated XML etc.).
  # @param  [String]  user_login         The current user's username.
  # @param  [String]  filetype           If not 'xml', the input is assumed to be an Excel spreadsheet.
  # @param  [String]  xml_only           If true, then only generate XML - do not upload into DOR.
  # @param  [String]  note               An optional note that the user entered to go with the job.
  # @return [Void]
  def perform(uploaded_filename, output_directory, user_login, filetype, xml_only, note)
    # The uploaded filename is of the form <file.xlsx.TIMESTAMP> or <file.xml.TIMESTAMP> in order to prevent
    # collisions when 2 people upload the same file. We don't want to display the timestamp later, though.
    original_filename = File.basename(uploaded_filename)
    original_filename = original_filename.slice(0, original_filename.rindex('.'))

    FileUtils.mkdir_p(output_directory) unless (File.directory?(output_directory))

    # This log will be used for generating the table of past jobs later
    log_filename = File.join(output_directory, Argo::Config.bulk_metadata_log)
    File.open(log_filename, 'w') { |log|
      start_timestamp = Time.now.strftime(TIME_FORMAT)
      log.puts("job_start #{start_timestamp}")
      log.puts("current_user #{user_login}")
      log.puts("input_file #{original_filename}")

      # Call the MODSulator web service to process the uploaded file. If a request fails, the job will fail
      # and automatically be retried, so we do not separately retry the HTTP request.
      response_xml = nil
      if (filetype == "xml")    # Just clean up the given XML file
        response_xml = RestClient.post(Argo::Config.urls.normalizer, :file => File.new(uploaded_filename, 'rb'), :filename => original_filename)
      else                               # The given file is a spreadsheet
        response_xml = RestClient.post(Argo::Config.urls.modsulator, :file => File.new(uploaded_filename, 'rb'), :filename => original_filename)
      end

      record_count = response_xml.scan('<xmlDoc id').size
      File.open(File.join(output_directory, Argo::Config.bulk_metadata_xml), "w") { |f| f.write(response_xml) }
      log.puts("xml_written #{Time.now.strftime(TIME_FORMAT)}")
      log.puts("records #{record_count}")

      log.puts("note #{note}") if (note)

      if (xml_only)
        log.puts("xml_only true")
      else
        # Load into DOR
        log.puts("xml_only false")
        update_metadata(response_xml, log)
      end

      finish_timestamp = Time.now.strftime(TIME_FORMAT)
      log.puts("job_finish #{finish_timestamp}")
    }

    # Remove the (temporary) uploaded file
    FileUtils.rm(uploaded_filename, :force => true)
  end

  # Upload metadata into DOR.
  #
  # @param  [String] xml_string    A MODS XML string.
  # @param  [File]   log           Log file handle.
  # @return [Void]
  def update_metadata(xml_string, log)
    root = Nokogiri::XML(xml_string).root
    namespace = root.namespace()

    # Loop through each <xmlDoc> node and add the MODS XML that it contains to the object's descMetadata
    mods_list = root.xpath('//x:xmlDoc', 'x' => namespace.href)
    mods_list.each do |mods_node|
      current_druid = 'druid:' + mods_node.attr('objectId')
      begin
        dor_object = Dor.find current_druid
        if (dor_object)
          dor_object.descMetadata.content = mods_node.to_s
          dor_object.save
          log.puts("saved #{current_druid}")
        end
      rescue ActiveFedora::ObjectNotFoundError
        log.puts("error_notfound #{current_druid}")
      end
    end
  end
end
