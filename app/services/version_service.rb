# frozen_string_literal: true

# Encapsulates all version-related functionality
class VersionService
  class << self
    # @returns [String] the current version
    def open(identifier:, **options)
      new(identifier:).open(**options)
    end

    def close(identifier:, **options)
      new(identifier:).close(**options)
    end

    def openable?(identifier:)
      new(identifier:).openable?
    end
  end

  attr_reader :identifier

  delegate :close, :open, :openable?, to: :version_client

  def initialize(identifier:)
    @identifier = identifier
  end

  private

  def version_client
    Dor::Services::Client.object(identifier).version
  end
end
