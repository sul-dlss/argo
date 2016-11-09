# Requests and parses index queues for Argo
class IndexQueue
  def initialize
  end

  ##
  # Gets the depth of the index queue
  # @return [Integer, nil]
  def depth
    parsed_response
  rescue Argo::Exceptions::IndexQueueInvalidResponse, Argo::Exceptions::IndexQueueRequestFailed => exception
    Honeybadger.notify(exception)
    nil
  end

  private

  ##
  # @return [String]
  def url
    Dor::Config.status.indexer_url
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
