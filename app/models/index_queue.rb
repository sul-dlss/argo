# frozen_string_literal: true

# Requests the depth of the index queue in dor_indexing_app
class IndexQueue
  ##
  # Gets the depth of the index queue
  # @return [Integer, nil]
  def depth
    parsed_response
  rescue Argo::Exceptions::IndexQueueInvalidResponse, Argo::Exceptions::IndexQueueRequestFailed => e
    Honeybadger.notify(e)
    nil
  end

  private

  ##
  # @return [String] the path to the queue depth endpoint on dor_indexing_app
  def url
    Settings.status_indexer_url
  end

  def parsed_response
    JSON.parse(response)['value']
  rescue JSON::ParserError, TypeError, NoMethodError
    raise Argo::Exceptions::IndexQueueInvalidResponse,
          "Could not parse the response from #{url} as JSON"
  end

  def response
    Faraday.get(url).body
  rescue SocketError, Faraday::Error
    raise Argo::Exceptions::IndexQueueRequestFailed,
          "Request to index queue at #{url} failed"
  end
end
