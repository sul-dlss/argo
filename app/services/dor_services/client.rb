# frozen_string_literal: true

module DorServices
  class Client
    include Singleton

    # Creates a new object in DOR
    # @return [HashWithIndifferentAccess] the response, which includes a :pid
    def self.register(params:)
      instance.register(params: params)
    end

    # @param [String] object the identifier for the object
    # @param [String] filename the name of the file to retrieve
    # @return [String] the file contents from the workspace
    def self.retrieve_file(object:, filename:)
      instance.retrieve_file(object: object, filename: filename)
    end

    # @param [String] object the identifier for the object
    # @return [Array<String>] the list of filenames in the workspace
    def self.list_files(object:)
      instance.list_files(object: object)
    end

    def register(params:)
      resp = connection.post do |req|
        req.url 'v1/objects'
        req.headers['Content-Type'] = 'application/json'
        req.body = params.to_json
      end
      raise "#{resp.reason_phrase}: #{resp.status} (#{resp.body})" unless resp.success?
      JSON.parse(resp.body).with_indifferent_access
    end

    def retrieve_file(object:, filename:)
      resp = connection.get do |req|
        req.url "v1/objects/#{object}/contents/#{filename}"
      end
      return unless resp.success?

      resp.body
    end

    def list_files(object:)
      resp = connection.get do |req|
        req.url "v1/objects/#{object}/contents"
      end
      return [] unless resp.success?

      json = JSON.parse(resp.body)
      json['items'].map { |item| item['name'] }
    end

    private

    def connection
      @connection ||= Faraday.new(Settings.DOR_SERVICES_URL)
    end
  end
end
