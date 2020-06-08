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

    def list(resource:)
      return {} unless resource.respond_to?(:versionMetadata)

      # add an entry with version id, tag and description for each version
      (1..resource.current_version.to_i).each_with_object({}) do |current_version_num, obj|
        obj[current_version_num] = {
          tag: resource.versionMetadata.tag_for_version(current_version_num.to_s),
          desc: resource.versionMetadata.description_for_version(current_version_num.to_s)
        }
      end
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
