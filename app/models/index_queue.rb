# Requests and parses index queues for Argo
class IndexQueue
  def initialize
  end

  ##
  # Gets the depth of the index queue
  # @return [Integer, nil]
  def depth
    parsed_response.to_i
  rescue Argo::Exceptions::IndexQueueInvalidResponse, Argo::Exceptions::IndexQueueRequestFailed => error
    Rails.logger.error "#{error.message}"
    return nil
  end

  private

  ##
  # @return [String]
  def url
    Dor::Config.status.indexer_url
  end

  def parsed_response
    JSON.parse(response.to_s).first['datapoints'].first.first
  rescue JSON::ParserError, TypeError, NoMethodError
    raise Argo::Exceptions::IndexQueueInvalidResponse,
          "Could not parse the response from #{url} as JSON"
  end

  def response
    RestClient::Request.execute(
      method: :get,
      url: url,
      timeout: timeout,
      open_timeout: timeout
    )
  rescue SocketError, RestClient::Exception
    raise Argo::Exceptions::IndexQueueRequestFailed,
          "Request to index queue at #{url} failed"
  end

  def timeout
    3
  end
end
