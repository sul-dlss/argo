# frozen_string_literal: true

# This class defines a Delayed Job task that is started when the user uploads a bulk metadata file for
# an APO. For configuration details, see app/config/initializers/delayed_job.rb.
class ModsulatorJob < ActiveJob::Base
  queue_as :default

  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = '%Y-%m-%d %H:%M%P'

  # This method is called by the caller running perform_later(), so we're using ActiveJob with Delayed Job as a backend.
  # The method does all the work of converting any input spreadsheets to XML, writing a log file as it goes along.
  # Later, this log file will be used to generate a nicer looking log for the user to view and to generate the list of
  # spreadsheet upload jobs within the Argo UI.
  #
  # @param  [String]  apo_id             DRUID of the DOR APO that governs all of the objects we're trying to upload metadata for.
  # @param  [String]  uploaded_filename  Full path to the temporary uploaded file. Deleted upon completion.
  # @param  [String]  output_directory   Where to store output (log, generated XML etc.).
  # @param  [String]  user_login         Acting user's username.
  # @param  [String]  filetype           One of 'xml, 'spreadsheet', or 'xml_only'. If not 'xml', the input is to be loaded into the datastream.
  # @param  [String]  note               An optional note that the user entered to go with the job.
  # @return [Void]
  def perform(apo_id, uploaded_filename, output_directory, user_login, filetype = 'spreadsheet', note = '')
    original_filename = generate_original_filename(uploaded_filename)
    log_filename = generate_log_filename(output_directory)
    persist_metadata = load_to_dor?(filetype)
    method = operation(filetype)

    File.open(log_filename, 'a') { |log|
      start_log(log, user_login, original_filename, note)

      # If a modsulator request fails, the job will fail and automatically be
      # retried (see config/initializers/delayed_job.rb)
      response_xml = if method == 'normalize'
                       ModsulatorClient.normalize_mods(uploaded_filename: uploaded_filename, pretty_filename: original_filename, log: log)
                     else
                       ModsulatorClient.convert_spreadsheet_to_mods(uploaded_filename: uploaded_filename, pretty_filename: original_filename, log: log)
                     end

      if response_xml.nil?
        log.puts('argo.bulk_metadata.bulk_log_error_exception Got no response from server')
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
        return nil
      end

      metadata_path = File.join(output_directory, generate_xml_filename(original_filename))
      save_metadata_xml(response_xml, metadata_path, log)

      if persist_metadata
        log.puts('argo.bulk_metadata.bulk_log_xml_only false')
        update_metadata(apo_id, response_xml, original_filename, user_login, log) # Load into DOR
      end

      log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
    }
    # Remove the (temporary) uploaded file only if everything worked. Removing upon catching an exception causes
    # subsequent job attempts to fail.
    FileUtils.rm(uploaded_filename, force: true)
  end

  # When filetype = 'xml' the user just wants to convert submitted spreadsheet to MODS. No need to load into DOR
  def load_to_dor?(filetype)
    filetype != 'xml'
  end

  def operation(filetype)
    filetype != 'xml_only' ? 'convert' : 'normalize'
  end

  # Upload metadata into DOR.
  #
  # @param  [String] druid               The governing APO's druid.
  # @param  [String] xml_string          A MODS XML string.
  # @param  [File]   log                 Log file handle.
  # @param  [String] user_login          The login name of the current user_login
  # @param  [String] original_filename   The name of the uploaded file
  # @return [Void]
  def update_metadata(druid, xml_string, original_filename, user_login, log)
    return if xml_string.nil?

    root = Nokogiri::XML(xml_string).root
    namespace = root.namespace()

    # Loop through each <xmlDoc> node and add the MODS XML that it contains to the object's descMetadata
    mods_list = root.xpath('//x:xmlDoc', 'x' => namespace.href)
    mods_list.each do |xmldoc_node|
      item_druid = "druid:#{xmldoc_node.attr('objectId')}"
      begin
        item = Dor::Item.find(item_druid)
        ApplyModsMetadata.new(apo_druid: druid,
                              mods_node: xmldoc_node.first_element_child,
                              item: item,
                              original_filename: original_filename,
                              user_login: user_login,
                              log: log).apply
      rescue ActiveFedora::ObjectNotFoundError => e
        log.puts("argo.bulk_metadata.bulk_log_not_exist #{item_druid}")
        log.puts(e.message.to_s)
        log.puts(e.backtrace.to_s)
      end
    end
  end

  # Generate a filename for the job's log file.
  #
  # @param  [String] output_dir Where to store the log file.
  # @return [String] A filename for the log file.
  def generate_log_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    # This log will be used for generating the table of past jobs later
    File.join(output_dir, Settings.BULK_METADATA.LOG)
  end

  # The uploaded filename is of the form <file.xlsx.TIMESTAMP> or <file.xml.TIMESTAMP> in order to prevent
  # collisions when 2 people upload the same file. We don't want to display the timestamp later, though, so this method
  # returns a nicer looking version of the filename.
  #
  # @param  [String] uploaded_filename  The full path to the temporary uploaded file.
  # @return [String] A prettier version of the uploaded filename.
  def generate_original_filename(uploaded_filename)
    original_filename = File.basename(uploaded_filename)
    original_filename.slice(0, original_filename.rindex('.'))
  end

  # Write initial job information to the log file.
  #
  # @param [File]    log_file  The log file to write to.
  # @param [String]  username  The login name of the current user.
  # @param [String]  filename  The name of this job's input file.
  # @param [String]  note      An optional comment that describes this job.
  def start_log(log_file, username, filename, note = '')
    log_file.puts("argo.bulk_metadata.bulk_log_job_start #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("argo.bulk_metadata.bulk_log_user #{username}")
    log_file.puts("argo.bulk_metadata.bulk_log_input_file #{filename}")
    log_file.puts("argo.bulk_metadata.bulk_log_note #{note}") if note && note.length > 0
    log_file.flush # record start in case of crash
  end

  # Writes the generated XML to a file named "metadata.xml" to disk and updates the log.
  #
  # @param  [String]  xml                An XML string, which will be written to output_filename.
  # @param  [String]  output_filename    The full path for where to store the XML file.
  # @param  [File]    log_file           The log file.
  # @return [Void]
  def save_metadata_xml(xml, output_filename, log_file)
    return if xml.nil?

    File.open(output_filename, 'w') { |f| f.write(xml) }
    log_file.puts("argo.bulk_metadata.bulk_log_xml_timestamp #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("argo.bulk_metadata.bulk_log_xml_filename #{File.basename(output_filename)}")
    log_file.puts("argo.bulk_metadata.bulk_log_record_count #{xml.scan('<xmlDoc id').size}")
  end

  # Generates a filename for the MODS XML that this job creates.
  #
  # @param  [String]   original_filename    The name of the original file that the user uploaded.
  # @return [String]
  def generate_xml_filename(original_filename)
    File.basename(original_filename, '.*') + '-' + Settings.BULK_METADATA.XML + '.xml'
  end
end
