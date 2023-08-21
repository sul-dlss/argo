# frozen_string_literal: true

# Encapsulates all version-related functionality
class VersionService
  class << self
    # @returns [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina object with updated version
    def open(identifier:, **)
      new(identifier:).open(**)
    end

    def close(identifier:, **)
      new(identifier:).close(**)
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
