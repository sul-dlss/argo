# frozen_string_literal: true

# Encapsulates all version-related functionality
class VersionService
  class << self
    # @returns [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina object with updated version
    def open(druid:, **)
      new(druid:).open(**)
    end

    def close(druid:, **)
      new(druid:).close(**)
    end

    def openable?(...)
      new(...).openable?
    end

    def open?(...)
      new(...).open?
    end

    def open_and_not_processing?(...)
      new(...).open_and_not_processing?
    end

    def assembling?(...)
      new(...).assembling?
    end

    def text_extracting?(...)
      new(...).text_extracting?
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

  attr_reader :druid

  delegate :close, :open, to: :version_client
  delegate :open?, :openable?, :assembling?, :text_extracting?, :accessioning?, :closed?, :closeable?, :version, to: :status

  def initialize(druid:)
    @druid = druid
  end

  def open_and_not_processing?
    open? && !assembling? && !text_extracting?
  end

  private

  def version_client
    @version_client ||= Dor::Services::Client.object(druid).version
  end

  def status
    @status ||= version_client.status
  end
end
