require 'nokogiri'

# This class defines a Delayed Job task that is started when the user uploads a bulk metadata file for
# an APO. For configuration details, see app/config/initializers/delayed_job.rb.
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
    original_filename = generate_original_filename(uploaded_filename)
    log_filename = generate_log_filename(output_directory)
    
    File.open(log_filename, 'w') { |log|

      start_log(log, user_login, original_filename, note)
      response_xml = generate_xml(filetype, uploaded_filename, original_filename)

      if(response_xml == nil)
        # can this happen and what should we do?
      end

      
      metadata_filename = generate_xml_filename(original_filename)
      save_metadata_xml(response_xml, File.join(output_directory, metadata_filename), log)

      if (xml_only)
        log.puts("xml_only true")
      elsif(filetype != 'xml')      # If the submitted file is XML, we never want to load anything into DOR
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


  # Generate a filename for the job's log file.
  #
  # @param  [String] output_dir Where to store the log file.
  # @return [String] A filename for the log file.
  def generate_log_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless (File.directory?(output_dir))

    # This log will be used for generating the table of past jobs later
    return log_filename = File.join(output_dir, Argo::Config.bulk_metadata_log)
  end


  # The uploaded filename is of the form <file.xlsx.TIMESTAMP> or <file.xml.TIMESTAMP> in order to prevent
  # collisions when 2 people upload the same file. We don't want to display the timestamp later, though, so this method
  # returns a nicer looking version of the filename.
  #
  # @param  [String] uploaded_filename  The full path to the temporary uploaded file.
  # @return [String] A prettier version of the uploaded filename.
  def generate_original_filename(uploaded_filename)
    original_filename = File.basename(uploaded_filename)
    return original_filename.slice(0, original_filename.rindex('.'))
  end


  # Write initial job information to the log file.
  #
  # @param [File]    log_file  The log file to write to.
  # @param [String]  username  The login name of the current user.
  # @param [String]  filename  The name of this job's input file.
  # @param [String]  note      An optional comment that describes this job.
  def start_log(log_file, username, filename, note)
    log_file.puts("job_start #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("current_user #{username}")
    log_file.puts("input_file #{filename}")
    log_file.puts("note #{note}") if (note && note.length > 0)
  end


  # Calls the MODSulator web service (modsulator-app) to process the uploaded file. If a request fails, the job will fail
  # and automatically be retried (see config/initializers/delayed_job.rb), so we do not separately retry the HTTP request.
  #
  # @param    [String]   filetype            The value 'xml' means that the given file is an XML file, and so should be submitted to the normalizer for cleanup.
  #                                          Any other values indicates a spreadsheet input (.xlsx).
  # @param    [String]   uploaded_filename   The full path to the XML/spreadsheet file.
  # @param    [String]   original_filename   A prettified filename, which looks better in the UI.
  # @return   [String]   XML, either generated from a given spreadsheet, or a normalized version of a given XML file.
  def generate_xml(filetype, uploaded_filename, original_filename)
    response_xml = nil

    if (filetype == "xml")    # Just clean up the given XML file
      response_xml = RestClient.post(Argo::Config.urls.normalizer, File.read(uploaded_filename))
    else                      # The given file is a spreadsheet
      response_xml = RestClient.post(Argo::Config.urls.modsulator, :file => File.new(uploaded_filename, 'rb'), :filename => original_filename)
    end
    return response_xml
  end


  # Writes the generated XML to a file named "metadata.xml" to disk and updates the log.
  #
  # @param  [String]  xml                An XML string, which will be written to output_filename.
  # @param  [String]  output_filename    The full path for where to store the XML file.
  # @param  [File]    log_file           The log file.
  # @return [Void]
  def save_metadata_xml(xml, output_filename, log_file)
    File.open(output_filename, "w") { |f| f.write(xml) }
    log_file.puts("xml_written #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("xml_filename #{File.basename(output_filename)}")
    log_file.puts("records #{xml.scan('<xmlDoc id').size}")
  end


  # Generates a filename for the MODS XML that this job creates.
  #
  # @param  [String]   original_filename    The name of the original file that the user uploaded.
  # @return [String]
  def generate_xml_filename(original_filename)
    return Argo::Config.bulk_metadata_xml + '_' + File.basename(original_filename, '.*') + '.xml'
  end
end
