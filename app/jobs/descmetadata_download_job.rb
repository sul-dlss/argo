class DescmetadataDownloadJob < ActiveJob::Base
  queue_as :default


  def perform(druid_list, job_status, output_directory)
    # foreach druid
      # download the descmetadata
      # add the descmetadata XML to a zip file
    druid_list.each do |current_druid|
      begin
        dor_object = Dor.find current_druid
        descMetadata = dor_object.descMetadata.content
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
