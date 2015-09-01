require 'nokogiri'
require 'equivalent-xml'

# This class defines a Delayed Job task that is started when the user uploads a bulk metadata file for
# an APO. For configuration details, see app/config/initializers/delayed_job.rb.
class ModsulatorJob < ActiveJob::Base
  queue_as :default

  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = "%Y-%m-%d %H:%M%P"

  # This method is called by the caller running perform_later(), so we're using ActiveJob with Delayed Job as a backend.
  # The method does all the work of converting any input spreadsheets to XML, writing a log file as it goes along.
  # Later, this log file will be used to generate a nicer looking log for the user to view and to generate the list of
  # spreadsheet upload jobs within the Argo UI.
  #
  # @param  [String]  apo_id             The druid of the DOR APO that governs all of the objects we're trying to upload metadata for.
  # @param  [String]  uploaded_filename  The full path to the temporary uploaded file. Will be deleted upon completion.
  # @param  [String]  output_directory   Where to store output (log, generated XML etc.).
  # @param  [String]  user_login         The current user's username.
  # @param  [String]  filetype           If not 'xml', the input is assumed to be an Excel spreadsheet.
  # @param  [String]  xml_only           If true, then only generate XML - do not upload into DOR.
  # @param  [String]  note               An optional note that the user entered to go with the job.
  # @return [Void]
  def perform(apo_id, uploaded_filename, output_directory, user_login, filetype, xml_only, note)
    original_filename = generate_original_filename(uploaded_filename)
    log_filename = generate_log_filename(output_directory)

    File.open(log_filename, 'w') { |log|

      start_log(log, user_login, original_filename, note)
      response_xml = generate_xml(filetype, uploaded_filename, original_filename, log)

      if(response_xml == nil)
        log.puts("argo.bulk_metadata.bulk_log_error_exception Got no response from server")
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
      end

      metadata_filename = generate_xml_filename(original_filename)
      save_metadata_xml(response_xml, File.join(output_directory, metadata_filename), log)

      if (xml_only)
        log.puts("argo.bulk_metadata.bulk_log_xml_only true")

      elsif(filetype != 'xml')      # If the submitted file is XML, we never want to load anything into DOR
        # Load into DOR
        log.puts("argo.bulk_metadata.bulk_log_xml_only false")
        update_metadata(apo_id, response_xml, log)
      end

      finish_timestamp = Time.now.strftime(TIME_FORMAT)
      log.puts("argo.bulk_metadata.bulk_log_job_complete #{finish_timestamp}")
    }

    # Remove the (temporary) uploaded file
    FileUtils.rm(uploaded_filename, :force => true)
  end

  
  # Upload metadata into DOR.
  #
  # @param  [String] druid         The governing APO's druid.
  # @param  [String] xml_string    A MODS XML string.
  # @param  [File]   log           Log file handle.
  # @return [Void]
  def update_metadata(druid, xml_string, log)
    root = Nokogiri::XML(xml_string).root
    namespace = root.namespace()

    # Loop through each <xmlDoc> node and add the MODS XML that it contains to the object's descMetadata
    mods_list = root.xpath('//x:xmlDoc', 'x' => namespace.href)
    mods_list.each do |mods_node|
      current_druid = 'druid:' + mods_node.attr('objectId')
      begin
        dor_object = Dor.find current_druid
        if (dor_object)
          if(dor_object.admin_policy_object_id == druid)
            current_metadata = dor_object.descMetadata.content
            Delayed::Worker.logger.debug("current_metadata = #{current_metadata}")
            Delayed::Worker.logger.debug("mods_node = #{mods_node}")
            Delayed::Worker.logger.debug("current_metadata ISA #{current_metadata.class}")

            dor_object.descMetadata.content = mods_node.to_s
            dor_object.save
            log.puts("argo.bulk_metadata.bulk_log_job_save_success #{current_druid}")
          else
            log.puts("argo.bulk_metadata.bulk_log_apo_fail #{current_druid}")
          end
        end
      rescue ActiveFedora::ObjectNotFoundError
        log.puts("argo.bulk_metadata.bulk_log_not_exist #{current_druid}")
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
    log_file.puts("argo.bulk_metadata.bulk_log_job_start #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("argo.bulk_metadata.bulk_log_user #{username}")
    log_file.puts("argo.bulk_metadata.bulk_log_input_file #{filename}")
    log_file.puts("argo.bulk_metadata.bulk_log_note #{note}") if (note && note.length > 0)
  end


  # Calls the MODSulator web service (modsulator-app) to process the uploaded file. If a request fails, the job will fail
  # and automatically be retried (see config/initializers/delayed_job.rb), so we do not separately retry the HTTP request.
  #
  # @param    [String]   filetype            The value 'xml' means that the given file is an XML file, and so should be submitted to the normalizer for cleanup.
  #                                          Any other values indicates a spreadsheet input (.xlsx).
  # @param    [String]   uploaded_filename   The full path to the XML/spreadsheet file.
  # @param    [String]   original_filename   A prettified filename, which looks better in the UI.
  # @param    [File]     log_file            The log file to write to
  # @return   [String]   XML, either generated from a given spreadsheet, or a normalized version of a given XML file.
  def generate_xml(filetype, uploaded_filename, original_filename, log_file)
    response_xml = nil
    url = nil

    begin
      if (filetype == "xml_only")  # Just clean up the given XML file
        url = Argo::Config.urls.normalizer
        response_xml = RestClient.post(url, File.read(uploaded_filename))
      else                         # The given file is a spreadsheet
        url = Argo::Config.urls.modsulator
        response_xml = RestClient.post(url, :file => File.new(uploaded_filename, 'rb'), :filename => original_filename)
      end
    rescue RestClient::ResourceNotFound => e
      delayed_log_url(e, url)
      log_file.puts "argo.bulk_metadata.bulk_log_invalid_url #{e.message}"
    rescue Errno::ENOENT => e
      delayed_log_url(e, url)
      log_file.puts "argo.bulk_metadata.bulk_log_nonexistent_file #{e.message}"
    rescue Errno::EACCES => e
      delayed_log_url(e, url)
      log_file.puts "argo.bulk_metadata.bulk_log_invalid_permission #{e.message}"
    rescue RestClient::InternalServerError => e
      delayed_log_url(e, url)
      log_file.puts "argo.bulk_metadata.bulk_log_internal_error #{e.message}"
    rescue Exception => e
      delayed_log_url(e, url)
      log_file.puts "argo.bulk_metadata.bulk_log_error_exception #{e.message}"
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
    log_file.puts("argo.bulk_metadata.bulk_log_xml_timestamp #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("argo.bulk_metadata.bulk_log_xml_filename #{File.basename(output_filename)}")
    log_file.puts("argo.bulk_metadata.bulk_log_record_count #{xml.scan('<xmlDoc id').size}")
  end


  # Generates a filename for the MODS XML that this job creates.
  #
  # @param  [String]   original_filename    The name of the original file that the user uploaded.
  # @return [String]
  def generate_xml_filename(original_filename)
    return File.basename(original_filename, '.*') + '-' + Argo::Config.bulk_metadata_xml + '.xml'
  end


  # Logs a remote request-related exception to the standard Delayed Job log file.
  #
  # @param  [Exception] e   The exception
  # @param  [String]    url The URL that we attempted to access
  # @return [Void]
  def delayed_log_url(e, url)
    Delayed::Worker.logger.error("#{__FILE__} tried to access #{url} got: #{e.message} #{e.backtrace}")
  end
end
