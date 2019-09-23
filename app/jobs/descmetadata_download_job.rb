# frozen_string_literal: true

require 'zip'

class DescmetadataDownloadJob < GenericJob
  queue_as :default

  MAX_TRIES = 3
  SLEEP_SECONDS = 3

  # @param [Integer] bulk_action_id ActiveRecord identifier of the BulkAction object that originated this job.
  # @param [Hash] params Custom params for this job
  # requires `:pids` (an Array of pids) and output_directory
  def perform(bulk_action_id, params)
    super
    zip_filename = generate_zip_filename(params[:output_directory])
    with_bulk_action_log do |log|
      #  Fail with an error message if the calling BulkAction doesn't exist
      if bulk_action.nil?
        log.puts("argo.bulk_metadata.bulk_log_bulk_action_not_found (looking for #{bulk_action_id})")
        log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
      else
        start_log(log, bulk_action.user_id, '', bulk_action.description)
        update_druid_count
        ::Zip::File.open(zip_filename, Zip::File::CREATE) do |zip_file|
          pids.each { |current_druid| process_druid(current_druid, log, zip_file) }
          zip_file.close
        end
      end
      log.puts("argo.bulk_metadata.bulk_log_job_complete #{Time.now.strftime(TIME_FORMAT)}")
    end
  end

  def process_druid(current_druid, log, zip_file)
    dor_object = query_dor(current_druid, log)
    if dor_object.nil?
      bulk_action.increment(:druid_count_fail).save
      return
    end

    unless ability.can?(:view_metadata, dor_object)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      return
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
  rescue StandardError => e
    log.puts("argo.bulk_metadata.bulk_log_error_exception #{current_druid}")
    log.puts(e.message)
    log.puts(e.backtrace)
    bulk_action.increment(:druid_count_fail).save
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
      sleep(SLEEP_SECONDS**attempts) unless Rails.env == 'test'
      retry
    else
      log.puts "argo.bulk_metadata.bulk_log_timeout #{druid}"
      return nil
    end
    return dor_object
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
    File.join(output_dir, Settings.bulk_metadata.zip)
  end
end
