# frozen_string_literal: true

# A client for calling the remote preservation service
class PreservationClient
  class ResponseError < StandardError; end

  # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
  def self.current_version(druid)
    new.current_version(druid)
  end

  def initialize
    @conn = conn
  end

  # @param [String] druid - with or without prefix: 'druid:ab123cd4567' OR 'ab123cd4567'
  def current_version(druid)
    resp = get("objects/#{druid}.json")
    raise ResponseError, "Got #{resp.status} retrieving version from Preservation Catalog at #{resp.env.url}: #{resp.body}" unless resp.success?

    json = JSON.parse(resp.body)
    json['current_version']
  end

  private

  def get(path)
    conn.get(path)
  rescue Faraday::ClientError => e
    errmsg = "HTTP GET to #{Settings.preservation_catalog.url}/#{path} failed with #{e.class}: #{e.message}"
    raise ResponseError, errmsg
  end

  def conn
    @conn || Faraday.new(url: Settings.preservation_catalog.url)
  end
end
