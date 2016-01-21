class DescmetadataDownloadJob < ActiveJob::Base
  queue_as :default

  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = '%Y-%m-%d %H:%M%P'

  # @param[Array<String>]  druid_list       Identifiers for what objects to act on.
  # @param[Integer]        bulk_action_id   ActiveRecord identifier of the BulkAction object that originated this job.
  # @param[String]         output_directory Where to store the log and zip files.
  def perform(druid_list, bulk_action_id, output_directory)
    Delayed::Worker.logger.debug('started the job')
    log_filename = generate_log_filename(output_directory)
    zip_filename = generate_zip_filename(output_directory)
    
    File.open(log_filename, 'w') { |log|
      Delayed::Worker.logger.debug('opende file')
      # Get the BulkAction that initiated this job and fail with an error message if it doesn't exist
      current_bulk_action = get_bulk_action(bulk_action_id)
      if current_bulk_action == nil
        log.puts("argo.bulk_metadata.bulk_log_bulk_action_not_found (looking for #{bulk_action_id})")
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
      else
        start_log(log, current_bulk_action.user_id, '', current_bulk_action.description)
        Delayed::Worker.logger.debug('about to open zip')
        Zip::File.open(zip_filename, Zip::File::CREATE) do |zip_file|
          druid_list.each do |current_druid|
            begin
              Delayed::Worker.logger.debug("starting to process druid #{current_druid}")
              dor_object = Dor.find current_druid
              descMetadata = dor_object.descMetadata.content
              Delayed::Worker.logger.debug("gotcontnet")
              write_to_zip(descMetadata, current_druid, zipfile)
              Delayed::Worker.logger.debug("wrotecontent")
              log.puts("argo.bulk_metadata.bulk_log_bulk_action_success #{current_druid}")
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
          zip_file.close
        end
      end
      
      log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
    }
  end


  def write_to_zip(value, entry_name, zip_file)
    zip_file.get_output_stream(entry_name) { |f| f.puts(value) }
  end


  # Write initial job information to the log file.
  #
  # @param [File]    log_file  The log file to write to.
  # @param [String]  username  The login name of the current user.
  # @param [String]  filename  An optional input filename
  # @param [String]  note      An optional comment that describes this job.
  def start_log(log_file, username, filename = '', note = '')
    log_file.puts("argo.bulk_metadata.bulk_log_job_start #{Time.now.strftime(TIME_FORMAT)}")
    log_file.puts("argo.bulk_metadata.bulk_log_user #{username}")
    log_file.puts("argo.bulk_metadata.bulk_log_input_file #{filename}") if filename && filename.length > 0
    log_file.puts("argo.bulk_metadata.bulk_log_note #{note}") if note && note.length > 0
    log_file.flush # record start in case of crash
  end

  
  # Generate a filename for the job's log file.
  #
  # @param  [String] output_dir Where to store the log file.
  # @return [String] A filename for the log file.
  def generate_log_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    # This log will be used for generating the table of past jobs later
    File.join(output_dir, Argo::Config.bulk_metadata_log)
  end


  # Generate a filename for the job's zip output file.
  #
  # @param  [String] output_dir Where to store the zip file.
  # @return [String] A filename for the zip file.
  def generate_zip_filename(output_dir)
    Delayed::Worker.logger.debug('about to open dir')
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    Delayed::Worker.logger.debug('about to open zip')
    File.join(output_dir, Argo::Config.bulk_metadata_zip)
  end

  
  # @param[Integer]       identifier   ActiveRecord identifier for a BulkAction object
  # @return[BulkAction]   The BulkAction corresponding to the given identifier, or nil if the BulkAction is not found
  def get_bulk_action(identifier)
    bulk_action_class = String.new('BulkAction').safe_constantize
    unless bulk_action_class == nil
      begin
        bulk_action_object = bulk_action_class.find(identifier)
        return bulk_action_object
      rescue ActiveRecord::RecordNotFound
        return nil
      end
    end
    return nil
  end
end
