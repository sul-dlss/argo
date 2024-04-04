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

    def openable?(...)
      new(...).openable?
    end

    def open?(...)
      new(...).open?
    end

    def assembling?(...)
      new(...).assembling?
    end

    def accessioning?(...)
      new(...).accessioning?
    end

    def closed?(...)
      new(...).closed?
    end

    def closeable?(...)
      new(...).closeable?
    end

    def version(...)
      new(...).version
    end
  end

  attr_reader :identifier

  delegate :close, :open, to: :version_client
  delegate :open?, :openable?, :assembling?, :accessioning?, :closed?, :closeable?, :version, to: :status

  def initialize(identifier:)
    @identifier = identifier
  end

  private

  def version_client
    @version_client ||= Dor::Services::Client.object(identifier).version
  end

  def status
    @status ||= version_client.status
  end
end
