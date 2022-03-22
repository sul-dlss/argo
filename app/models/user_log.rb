# frozen_string_literal: true

class UserLog
  # List the messages that we're going to display to the end user
  USER_MESSAGES = Set.new ['argo.bulk_metadata.bulk_log_job_start',
                           'argo.bulk_metadata.bulk_log_job_complete',
                           'argo.bulk_metadata.bulk_log_job_save_success',
                           'argo.bulk_metadata.bulk_log_apo_fail',
                           'argo.bulk_metadata.bulk_log_not_exist',
                           'argo.bulk_metadata.bulk_log_note',
                           'argo.bulk_metadata.bulk_log_record_count',
                           'argo.bulk_metadata.bulk_log_error_exception',
                           'argo.bulk_metadata.bulk_log_validation_error',
                           'argo.bulk_metadata.bulk_log_invalid_column',
                           'argo.bulk_metadata.bulk_log_skipped_mods',
                           'argo.bulk_metadata.bulk_log_invalid_druid',
                           'argo.bulk_metadata.bulk_log_skipped_accession',
                           'argo.bulk_metadata.bulk_log_skipped_not_accessioned',
                           'argo.bulk_metadata.bulk_log_no_connection',
                           'argo.bulk_metadata.bulk_log_invalid_url',
                           'argo.bulk_metadata.bulk_log_nonexistent_file',
                           'argo.bulk_metadata.bulk_log_invalid_permission',
                           'argo.bulk_metadata.bulk_log_druids_loaded',
                           'argo.bulk_metadata.bulk_log_internal_error',
                           'argo.bulk_metadata.bulk_log_unable_to_version']

  # List the subset of messages that indicate an error with the job
  ERROR_MESSAGES = Set.new ['argo.bulk_metadata.bulk_log_apo_fail',
                            'argo.bulk_metadata.bulk_log_not_exist',
                            'argo.bulk_metadata.bulk_log_invalid_druid',
                            'argo.bulk_metadata.bulk_log_error_exception',
                            'argo.bulk_metadata.bulk_log_validation_error',
                            'argo.bulk_metadata.bulk_log_invalid_column',
                            'argo.bulk_metadata.bulk_log_no_connection',
                            'argo.bulk_metadata.bulk_log_invalid_url',
                            'argo.bulk_metadata.bulk_log_nonexistent_file',
                            'argo.bulk_metadata.bulk_log_invalid_permission',
                            'argo.bulk_metadata.bulk_log_internal_error',
                            'argo.bulk_metadata.bulk_log_unable_to_version']

  attr_reader :apo_id, :time

  # @param [String] apo_id The governing APO's druid
  # @param [String] time the timestamp for the directory
  def initialize(apo_id, time)
    @apo_id = apo_id
    @time = time
  end

  # Creates an array of user friendly log messages from the bulk upload log.
  #
  # @return [Array<Hash>] The hash keys are strings defined in en.yml and the values are string messages.
  def user_messages
    @user_messages ||= begin
      log_items ||= []
      druids_loaded = 0

      # Each line in the log is assumed to be of the format "<keyword> <string>", where <keyword> is a phrase from
      # the en.yml file and <string> is a more informative message. Note that <string> may be empty for certain exceptions.
      each_line do |log_line|
        split_line = log_line.split(/\s+/, 2)

        # A few of the log messages are considered 'too technical' and will not be displayed
        next unless !split_line.empty? && USER_MESSAGES.include?(split_line[0])

        # Ignore lines that don't conform to the format
        current_hash = {}
        case split_line.length
        when 2
          druids_loaded += 1 if split_line[0] == 'argo.bulk_metadata.bulk_log_job_save_success'
          current_hash[split_line[0]] = split_line[1]
          log_items.push(current_hash)
        when 1
          current_hash[log_line.strip] = nil
          log_items.push(current_hash)
        end
      end
      log_items.push('argo.bulk_metadata.bulk_log_druids_loaded' => druids_loaded)
      log_items
    end
  end

  # Given a directory with bulk metadata upload information (written by ModsulatorJob), loads the job data into a hash.
  def bulk_job_metadata
    success = 0
    job_info = {}
    each_line do |line|
      # The log file is a very simple flat file (whitespace separated) format where the first token denotes the
      # field/type of information and the rest is the actual value.
      matched_strings = line.match(/^([^\s]+)\s+(.*)/)
      next unless matched_strings && matched_strings.length == 3

      job_info[matched_strings[1]] = matched_strings[2]
      success += 1 if matched_strings[1] == 'argo.bulk_metadata.bulk_log_job_save_success'
      job_info['error'] = 1 if UserLog::ERROR_MESSAGES.include?(matched_strings[1])
    end
    unless job_info.empty?
      job_info['dir'] = File.join(apo_id, time)
      job_info['argo.bulk_metadata.bulk_log_druids_loaded'] = success
    end
    job_info
  end

  # Creates a CSV file from the log messages generated by load_user_log. The CSV file is stored in the bulk
  # upload output directory.
  # @return [Void]
  def create_csv_log
    File.open(csv_file, 'w') do |csv_file|
      user_messages.each do |message|
        key = message.keys[0]

        csv_file.puts("\"#{I18n.t(key)}\",\"#{message[key]}\"") if USER_MESSAGES.include?(key)
      end
    end
  end

  # @return [String] the path to the csv file
  def csv_file
    @csv_file ||= File.join(job_output_directory, Settings.bulk_metadata.csv_log)
  end

  # @return [String] the path to the xml file
  def desc_metadata_xml_file
    filename = bulk_job_metadata.fetch('argo.bulk_metadata.bulk_log_xml_filename')
    File.join(job_output_directory, filename)
  end

  private

  def each_line
    return unless File.exist?(log_file) && File.readable?(log_file)

    File.open(log_file, 'r') do |file|
      file.each_line do |line|
        yield line
      end
    end
  end

  # @return [String] the path to the log file
  def log_file
    @log_file ||= File.join(job_output_directory, Settings.bulk_metadata.log)
  end

  # @return [String] The bulk upload job output directory
  def job_output_directory
    @job_output_directory ||= File.join(Settings.bulk_metadata.directory, apo_id, time)
  end
end
