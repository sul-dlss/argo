# frozen_string_literal: true

# Encapsulates all version-related functionality
class VersionService
  class << self
    def open(identifier:, **options)
      new(identifier: identifier).open(**options)
    end

    def close(identifier:, **options)
      new(identifier: identifier).close(**options)
    end

    def openable?(identifier:)
      new(identifier: identifier).openable?
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
