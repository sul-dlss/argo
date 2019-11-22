# frozen_string_literal: true

# Creates virtual objects using the dor services API
class VirtualObjectsCreator
  SECONDS_BETWEEN_REQUESTS = 10

  # @param [Array] virtual_objects an array of virtual object hashes
  # @return [Array] an array of errors (empty if no errors)
  def self.create(virtual_objects:)
    new(virtual_objects: virtual_objects).create
  end

  attr_reader :virtual_objects

  # @param [Array] virtual_objects an array of virtual object hashes
  def initialize(virtual_objects:)
    raise ArgumentError, 'virtual_objects must be a non-empty array' if !virtual_objects.is_a?(Array) || virtual_objects.empty?

    @virtual_objects = virtual_objects
  end

  # @return [Array] an array of errors (empty if no errors)
  def create
    background_result_url = Dor::Services::Client.virtual_objects.create(virtual_objects: virtual_objects)
    job_output = poll_until_complete(url: background_result_url)
    # If job output hash lacks an `:errors` key, we interpret that as complete success
    return [] if job_output[:errors].nil?

    Honeybadger.notify("Argo virtual object job errors from #{background_result_url}: #{job_output[:errors].inspect}")

    job_output[:errors].map do |error|
      Honeybadger.notify("Argo virtual object job errors from #{background_result_url}: #{job_output[:errors].inspect}") if error.nil?
      "Problem children for #{error.keys.first}: #{error.values.flatten.to_sentence}"
    end
  end

  private

  # @param [String] url the URL we should poll for updates
  # @return [Hash] a hash of output from the background job
  def poll_until_complete(url:)
    loop do
      results = Dor::Services::Client.background_job_results.show(job_id: job_id_from(url: url))

      if results[:status] != 'complete'
        sleep(SECONDS_BETWEEN_REQUESTS)
        redo
      end

      Honeybadger.notify("Argo received background job results from #{url}: #{results[:output].inspect}")

      break results[:output]
    end
  end

  def job_id_from(url:)
    url.split('/').last
  end
end
