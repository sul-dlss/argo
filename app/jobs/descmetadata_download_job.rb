class DescmetadataDownloadJob < ActiveJob::Base
  queue_as :default


  # @param[Array<String>]  druid_list       Identifiers for what objects to act on.
  # @param[Integer]        bulk_action_id   ActiveRecord identifier of the BulkAction object that originated this job.
  # @param[String]         output_directory Where to store the log and zip files.
  def perform(druid_list, bulk_action_id, output_directory)
    log_filename = generate_log_filename(output_directory)
    zip_filename = generate_zip_filename(output_directory)
    Delayed::Worker.logger.debug("before open #{zip_filename}")
    File.open(log_filename, 'w') { |log|
      # Get the BulkAction that initiated this job and fail with an error message if it doesn't exist
      current_bulk_action = get_bulk_action(bulk_action_id)
      if current_bulk_action == nil
        log.puts("argo.bulk_metadata.bulk_log_bulk_action_not_found (looking for #{bulk_action_id})")
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
      else
        start_log(log, current_bulk_action.user_id, '', current_bulk_action.description)

        Zip::File.open(zip_filename, Zip::File::CREATE) do |zip_file|
          druid_list.each do |current_druid|
            begin
              dor_object = Dor.find current_druid
              descMetadata = dor_object.descMetadata.content

              write_to_zip(descMetadata, current_druid, zip_file)
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
    }
  end
end
