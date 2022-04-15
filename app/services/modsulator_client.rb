# frozen_string_literal: true

# A client for calling the remote modsulator service
class ModsulatorClient
  # Wait 30 minutes for remote requests to complete
  TIMEOUT = 1800

  # Converts a spreadsheet to MODS by calling the remote modsulator service
  # @param [String] uploaded_filename The full path to the spreadsheet file.
  # @param [String] pretty_filename A prettified version of the filename. Modsulator writes this to xmlDocs[@sourceFile].
  # @param [#puts] log the logger to write to
  # @return [String] XML generated from a given spreadsheet
  def self.convert_spreadsheet_to_mods(uploaded_filename:, pretty_filename:, log:)
    new(uploaded_filename:, pretty_filename:, log:).convert_spreadsheet_to_mods
  end

  # Normalizes MODS by calling the remote modsulator service
  # @param [String] uploaded_filename The full path to the XML file.
  # @param [String] pretty_filename A prettified version of the filename. Modsulator writes this to xmlDocs[@sourceFile].
  # @param [#puts] log the logger to write to
  # @return [String] a normalized version of a given XML file.
  def self.normalize_mods(uploaded_filename:, pretty_filename:, log:)
    new(uploaded_filename:, pretty_filename:, log:).normalize_mods
  end

  # @param [String] uploaded_filename The full path to the Spreadsheet/XML file.
  # @param [String] pretty_filename A prettified version of the filename. Modsulator writes this to xmlDocs[@sourceFile].
  # @param [#puts(String)] log handle to output stream from caller (e.g. to provide user with job-specific log file)
  def initialize(uploaded_filename:, pretty_filename:, log:)
    @uploaded_filename = uploaded_filename
    @pretty_filename = pretty_filename
    @log = log
  end

  def normalize_mods
    call_remote_modsulator(Settings.normalizer_url, 'application/xml')
  end

  def convert_spreadsheet_to_mods
    call_remote_modsulator(Settings.modsulator_url, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
  end

  private

  attr_reader :uploaded_filename, :log, :pretty_filename

  # Calls the MODSulator web service (modsulator-app) to process the uploaded file.
  # Retries are handled by ActiveJob, so don't retry here.
  #
  # @param    [String]   url                 Then endpoint to call
  # @param    [String]   content_type        The mime type of the object
  # @return   [String]   XML, either generated from a given spreadsheet, or a normalized version of a given XML file.
  def call_remote_modsulator(url, content_type)
    response_xml = nil
    payload = Faraday::Multipart::FilePart.new(uploaded_filename, content_type)

    connection = Faraday.new(url:) do |faraday|
      faraday.use Faraday::Response::RaiseError
      faraday.request :multipart
      faraday.request :url_encoded
      faraday.adapter :net_http # A MUST for file upload to work with Faraday::Multipart::FilePart
    end

    response_xml = connection.post do |req|
      req.url url
      req.options.timeout = TIMEOUT
      req.options.open_timeout = TIMEOUT
      req.body = { file: payload, filename: pretty_filename }
    end
    response_xml.body
  rescue Faraday::ResourceNotFound => e
    log_request_error(e, url, 'argo.bulk_metadata.bulk_log_invalid_url')
  rescue Errno::ENOENT => e
    log_request_error(e, url, 'argo.bulk_metadata.bulk_log_nonexistent_file')
  rescue Errno::EACCES => e
    log_request_error(e, url, 'argo.bulk_metadata.bulk_log_invalid_permission')
  rescue Faraday::Error => e
    log_request_error(e, url, 'argo.bulk_metadata.bulk_log_internal_error')
  rescue StandardError => e
    log_request_error(e, url, 'argo.bulk_metadata.bulk_log_error_exception')
  ensure
    log.puts "argo.bulk_metadata.bulk_log_empty_response ERROR: No response from #{url}" if response_xml.nil?
  end

  # Logs a remote request-related exception to the standard ActiveJob log file.
  #
  # @param  [Exception] e   The exception
  # @param  [String]    url The URL that we attempted to access
  # @param  [String]    error_code a string prefix denoting the category of error, for the external log stream
  # @return [Void]
  def log_request_error(error, url, error_code)
    Rails.logger.error("#{__FILE__} tried to access #{url} got: #{error.message} #{error.backtrace}")
    log.puts "#{error_code} #{error.message}"
  end
end
