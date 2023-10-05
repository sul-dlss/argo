# frozen_string_literal: true

module Mods
  # This is the license entity used for translating a license URL into text on
  # to be added to the public descriptive metadata
  class License
    attr_reader :description, :uri

    # Raised when the license provided is not valid
    class LegacyLicenseError < StandardError; end

    def self.licenses
      @licenses ||= Rails.application.config_for(:licenses, env: 'production').stringify_keys
    end

    def initialize(url:)
      raise LegacyLicenseError unless License.licenses.key?(url)

      attrs = License.licenses.fetch(url)
      @uri = url
      @description = attrs.fetch(:description)
    end
  end
end
