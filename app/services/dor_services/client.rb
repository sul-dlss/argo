# frozen_string_literal: true

module DorServices
  class Client
    attr_reader :params

    def self.register(params:)
      new(params: params).register
    end

    def initialize(params:)
      @params = params
    end

    def register
      resp = connection.post do |req|
        req.url 'v1/objects'
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      JSON.parse(resp.body).with_indifferent_access
    end

    private

    def connection
      @connection ||= Faraday.new(Settings.DOR_SERVICES_URL)
    end
  end
end
