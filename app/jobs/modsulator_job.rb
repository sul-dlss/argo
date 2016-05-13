require 'nokogiri'
require 'equivalent-xml'
include DorObjectHelper

# This class defines a Delayed Job task that is started when the user uploads a bulk metadata file for
# an APO. For configuration details, see app/config/initializers/delayed_job.rb.
class ModsulatorJob < ActiveJob::Base
  queue_as :default

  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = '%Y-%m-%d %H:%M%P'

  # Wait 30 minutes for remote requests to complete
  TIMEOUT = 1800

  # This method is called by the caller running perform_later(), so we're using ActiveJob with Delayed Job as a backend.
  # The method does all the work of converting any input spreadsheets to XML, writing a log file as it goes along.
  # Later, this log file will be used to generate a nicer looking log for the user to view and to generate the list of
  # spreadsheet upload jobs within the Argo UI.
  #
  # @param  [String]  apo_id             DRUID of the DOR APO that governs all of the objects we're trying to upload metadata for.
  # @param  [String]  uploaded_filename  Full path to the temporary uploaded file. Deleted upon completion.
  # @param  [String]  output_directory   Where to store output (log, generated XML etc.).
  # @param  [String]  user_login         Acting user's username.
  # @param  [String]  filetype           If not 'xml', the input is assumed to be an Excel spreadsheet.
  # @param  [Boolean]  xml_only          If true, then only generate XML - do not upload into DOR.
  # @param  [String]  note               An optional note that the user entered to go with the job.
  # @return [Void]
  def perform(apo_id, uploaded_filename, output_directory, user_login, filetype = 'xlsx', xml_only = false, note = '')
    original_filename = generate_original_filename(uploaded_filename)
    log_filename = generate_log_filename(output_directory)

    File.open(log_filename, 'w') { |log|

      start_log(log, user_login, original_filename, note)
      response_xml = generate_xml(filetype, uploaded_filename, original_filename, log)

      if response_xml.nil?
        log.puts('argo.bulk_metadata.bulk_log_error_exception Got no response from server')
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
        return nil
      end

      metadata_path = File.join(output_directory, generate_xml_filename(original_filename))
      save_metadata_xml(response_xml, metadata_path, log)

      if xml_only
        log.puts('argo.bulk_metadata.bulk_log_xml_only true')
      elsif filetype != 'xml' # If the submitted file is XML, we never want to load anything into DOR
        log.puts('argo.bulk_metadata.bulk_log_xml_only false')
        update_metadata(apo_id, response_xml, original_filename, user_login, log) # Load into DOR
      end

      log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
    }
  ensure
    FileUtils.rm(uploaded_filename, :force => true) # Remove the (temporary) uploaded file
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
      current_druid = 'druid:' + xmldoc_node.attr('objectId')
      begin
        dor_object = Dor.find current_druid
        next unless dor_object

        # Only update objects that are governed by the correct APO
        unless dor_object.admin_policy_object_id == druid
          log.puts("argo.bulk_metadata.bulk_log_apo_fail #{current_druid}")
          next
        end
        if in_accessioning(dor_object)
          log.puts("argo.bulk_metadata.bulk_log_skipped_accession #{current_druid}")
          next
        end

        next unless status_ok(dor_object)

        # We only update objects if the descMetadata XML is different
        current_metadata = dor_object.descMetadata.content
        mods_node = xmldoc_node.first_element_child
        if equivalent_nodes(Nokogiri::XML(current_metadata).root, mods_node)
          log.puts("argo.bulk_metadata.bulk_log_skipped_mods #{current_druid}")
          next
        end

        version_object(dor_object, original_filename, user_login, log)

        dor_object.descMetadata.content = mods_node.to_s
        dor_object.save
        log.puts("argo.bulk_metadata.bulk_log_job_save_success #{current_druid}")
      rescue ActiveFedora::ObjectNotFoundError => e
        log.puts("argo.bulk_metadata.bulk_log_not_exist #{current_druid}")
        log.puts("#{e.message}")
        log.puts("#{e.backtrace}")
        next
      rescue Dor::Exception, Exception => e
        log.puts("argo.bulk_metadata.bulk_log_error_exception #{current_druid}")
        log.puts("#{e.message}")
        log.puts("#{e.backtrace}")
        next
      end
    end
  end

  # Open a new version for the given object if it is in the accessioned state.
  # @param   [Dor::Item]  dor_object          The object to version
  # @param   [String]     original_filename   The name of the uploaded file
  # @param   [String]     user_login          The current user_login
  # @param   [File]       log                 Log file handle
  def version_object(dor_object, original_filename, user_login, log)
    if accessioned(dor_object)
      if !DorObjectWorkflowStatus.new(dor_object.pid).can_open_version?
        log.puts("argo.bulk_metadata.bulk_log_unable_to_version #{dor_object.pid}")  # totally unexpected
        return
      end
      commit_new_version(dor_object, original_filename, user_login)
    end
  end

  # Open a new version for the given object.
  # @param   [Dor::Item]  dor_object          The object to version
  # @param   [String]     original_filename   The name of the uploaded file
  # @param   [String]     user_login          The current user_login
  def commit_new_version(dor_object, original_filename, user_login)
    vers_md_upd_info = {
      :significance => 'minor',
      :description => "Descriptive metadata upload from #{original_filename}",
      :opening_user_name => user_login
    }
    dor_object.open_new_version({:vers_md_upd_info => vers_md_upd_info})
  end

  # Returns true if the given object is accessioned, false otherwise.
  # @param   [Dor::Item]  dor_object  A DOR object
  def accessioned(dor_object)
    (6..8).cover?(dor_object.status_info[:status_code])
  end

  # Check if two MODS XML nodes are equivalent.
  #
  # @param [Nokogiri::XML::Element]  node_1  A MODS XML node.
  # @param [Nokogiri::XML::Element]  node_2  A MODS XML node.
  # @return [Boolean] true if the given nodes are equivalent, false otherwise.
  def equivalent_nodes(node_1, node_2)
    EquivalentXml.equivalent?(node_1,
                              node_2,
                              :element_order => false,
                              :normalize_whitespace => true,
                              :ignore_attr_values => ['version', 'xmlns', 'xmlns:xsi', 'schemaLocation'])
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
    content_type = nil

    if filetype == 'xml_only'            # Just clean up the given XML file
      url = Settings.NORMALIZER_URL
      content_type = 'application/xml'
    else                                 # The given file is a spreadsheet
      url = Settings.MODSULATOR_URL
      content_type = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    end

    request = RestClient::Request.new(:method => :post,
                                      :url => url,
                                      :timeout => TIMEOUT,
                                      :payload => {
                                        :multipart => true,
                                        :file => File.new(uploaded_filename, 'rb'),
                                        :filename => original_filename
                                      },
                                      :headers => {
                                        :content_type => content_type,
                                        :accept_charset => 'utf-8'
                                      })
    response_xml = request.execute
    response_xml
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
  ensure
    log_file.puts "argo.bulk_metadata.bulk_log_empty_response ERROR: No response from #{url}" if response_xml.nil?
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

  # Logs a remote request-related exception to the standard Delayed Job log file.
  #
  # @param  [Exception] e   The exception
  # @param  [String]    url The URL that we attempted to access
  # @return [Void]
  def delayed_log_url(e, url)
    Delayed::Worker.logger.error("#{__FILE__} tried to access #{url} got: #{e.message} #{e.backtrace}")
  end

  # Checks whether or not a DOR object is in accessioning or not.
  #
  # @param  [Dor::Item]   dor_object    DOR object to check
  # @return [Boolean]     true if the object is currently being accessioned, false otherwise
  def in_accessioning(dor_object)
    status = dor_object.status_info[:status_code]
    (2..5).cover?(status)
  end

  # Checks whether or not a DOR object's status is OK for a descMetadata update. Basically, the only times we are
  # not OK to update is if the object is currently being accessioned and if the object has status unknown.
  #
  # @param  [Dor::Item]   dor_object    DOR object to check
  # @return [Boolean]     true if the object's status allows us to update the descMetadata datastream, false otherwise
  def status_ok(dor_object)
    status = dor_object.status_info[:status_code]
    [1, 6, 7, 8, 9].include?(status)
  end
end
