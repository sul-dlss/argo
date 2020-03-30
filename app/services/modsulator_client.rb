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
    new(uploaded_filename: uploaded_filename, pretty_filename: pretty_filename, log: log).convert_spreadsheet_to_mods
  end

  # Normalizes MODS by calling the remote modsulator service
  # @param [String] uploaded_filename The full path to the XML file.
  # @param [String] pretty_filename A prettified version of the filename. Modsulator writes this to xmlDocs[@sourceFile].
  # @param [#puts] log the logger to write to
  # @return [String] a normalized version of a given XML file.
  def self.normalize_mods(uploaded_filename:, pretty_filename:, log:)
    new(uploaded_filename: uploaded_filename, pretty_filename: pretty_filename, log: log).normalize_mods
  end

  # @param [String] uploaded_filename The full path to the Spreadsheet/XML file.
  # @param [String] pretty_filename A prettified version of the filename. Modsulator writes this to xmlDocs[@sourceFile].
  # @param [#puts] log the logger to write to
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
  # Retries are handled by DelayedJob, so don't retry here.
  #
  # @param    [String]   url                 Then endpoint to call
  # @param    [String]   content_type        The mime type of the object
  # @return   [String]   XML, either generated from a given spreadsheet, or a normalized version of a given XML file.
  def call_remote_modsulator(url, content_type)
    response_xml = nil
    payload = Faraday::UploadIO.new(uploaded_filename, content_type)

    connection = Faraday.new(url: url) do |faraday|
      faraday.use Faraday::Response::RaiseError
      faraday.request :multipart
      faraday.request :url_encoded
      faraday.adapter :net_http # A MUST for file upload to work with UploadIO
    end

    response_xml = connection.post do |req|
      req.url url
      req.options.timeout = TIMEOUT
      req.options.open_timeout = TIMEOUT
      req.body = { file: payload, filename: pretty_filename }
    end
    response_xml.body
  rescue Faraday::ResourceNotFound => e
    delayed_log_url(e, url)
    log.puts "argo.bulk_metadata.bulk_log_invalid_url #{e.message}"
  rescue Errno::ENOENT => e
    delayed_log_url(e, url)
    log.puts "argo.bulk_metadata.bulk_log_nonexistent_file #{e.message}"
  rescue Errno::EACCES => e
    delayed_log_url(e, url)
    log.puts "argo.bulk_metadata.bulk_log_invalid_permission #{e.message}"
  rescue Faraday::Error => e
    delayed_log_url(e, url)
    log.puts "argo.bulk_metadata.bulk_log_internal_error #{e.message}"
  rescue StandardError => e
    delayed_log_url(e, url)
    log.puts "argo.bulk_metadata.bulk_log_error_exception #{e.message}"
  ensure
    log.puts "argo.bulk_metadata.bulk_log_empty_response ERROR: No response from #{url}" if response_xml.nil?
  end

  # Logs a remote request-related exception to the standard Delayed Job log file.
  #
  # @param  [Exception] e   The exception
  # @param  [String]    url The URL that we attempted to access
  # @return [Void]
  def delayed_log_url(error, url)
    Delayed::Worker.logger.error("#{__FILE__} tried to access #{url} got: #{error.message} #{error.backtrace}")
  end
end
