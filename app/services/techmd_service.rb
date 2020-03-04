# frozen_string_literal: true

# Retrieves technical metadata from the Technical Metadata Service
class TechmdService
  def self.techmd_for(druid:)
    resp = Faraday.get("#{Settings.tech_md_service.url}/v1/technical-metadata/druid/#{druid}") do |req|
      req.headers['Accept'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{Settings.tech_md_service.token}"
    end
    return JSON.parse(resp.body) if resp.status == 200
    return [] if resp.status == 404

    raise "Unexpected response (#{resp.status}) from technical-metadata-service for #{druid}: #{resp.body}"
  end
end
