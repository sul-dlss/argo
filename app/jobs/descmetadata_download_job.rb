class DescmetadataDownloadJob < GenericJob
  queue_as :default

  MAX_TRIES = 3
  SLEEP_SECONDS = 3

  ##
  # @param [Integer] bulk_action_id   ActiveRecord identifier of the BulkAction
  # object that originated this job.
  # @param [Hash] params Custom params for this job. DescmetadataDownloadJob
  # requires `:pids` (an Array of pids) and output_directory
  def perform(bulk_action_id, params)
    zip_filename = generate_zip_filename(params[:output_directory])
    initialize_counters(bulk_action)
    File.open(bulk_action.log_name, 'w') do |log|
      #  Fail with an error message if the calling BulkAction doesn't exist
      if bulk_action.nil?
        log.puts("argo.bulk_metadata.bulk_log_bulk_action_not_found (looking for #{bulk_action_id})")
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
      else
        start_log(log, bulk_action.user_id, '', bulk_action.description)

        bulk_action.update(druid_count_total: params[:pids].length)
        bulk_action.save
        Zip::File.open(zip_filename, Zip::File::CREATE) do |zip_file|
          params[:pids].each do |current_druid|
            begin
              dor_object = query_dor(current_druid, log)

              if dor_object.nil?
                bulk_action.increment(:druid_count_fail).save
                next
              end

              desc_metadata = dor_object.descMetadata.content

              write_to_zip(desc_metadata, current_druid, zip_file)
              log.puts("argo.bulk_metadata.bulk_log_bulk_action_success #{current_druid}")
              bulk_action.increment(:druid_count_success).save
            rescue ActiveFedora::ObjectNotFoundError => e
              log.puts("argo.bulk_metadata.bulk_log_not_exist #{current_druid}")
              log.puts(e.message)
              log.puts(e.backtrace)
              bulk_action.increment(:druid_count_fail).save
              next
            rescue Dor::Exception, StandardError => e
              log.puts("argo.bulk_metadata.bulk_log_error_exception #{current_druid}")
              log.puts(e.message)
              log.puts(e.backtrace)
              bulk_action.increment(:druid_count_fail).save
              next
            end
          end
          zip_file.close
        end
      end
      log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
    end
  end

  # Queries DOR for a given druid, attempting up to MAX_TRIES times in case of failure.
  # @param [String]   druid   The ID of the object to find
  # @param [File]     log     Log file to write to
  # @return  The Dor::Item corresponding to the given druid, or nil if none was found.
  def query_dor(druid, log)
    attempts ||= MAX_TRIES
    dor_object = Dor.find druid
  rescue RestClient::RequestTimeout
    if (attempts -= 1) > 0
      log.puts "argo.bulk_metadata.bulk_log_retry #{druid}"
      sleep(SLEEP_SECONDS ** attempts) unless ENV['RAILS_ENV'] == 'test'
      retry
    else
      log.puts "argo.bulk_metadata.bulk_log_timeout #{druid}"
      return nil
    end
    return dor_object
  end

  # Initialize the counters for the originating bulk action. This is necessary to avoid invalid counters
  # in case of the job is restarted.
  def initialize_counters(bulk_action)
    bulk_action.update(druid_count_fail: 0)
    bulk_action.update(druid_count_success: 0)
    bulk_action.update(druid_count_total: 0)
  end

  def write_to_zip(value, entry_name, zip_file)
    zip_file.get_output_stream("#{entry_name}.xml") { |f| f.puts(value) }
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

  ##
  # Generate a filename for the job's zip output file.
  # @param  [String] output_dir Where to store the zip file.
  # @return [String] A filename for the zip file.
  def generate_zip_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    File.join(output_dir, Settings.BULK_METADATA.ZIP)
  end
end
