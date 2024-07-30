# frozen_string_literal: true

module Contents
  class PreservationLinkComponent < ApplicationComponent
    def initialize(druid:, cocina_file:, has_been_accessioned:, version:)
      @druid = druid
      @cocina_file = cocina_file
      @has_been_accessioned = has_been_accessioned
      @version = version
    end

    attr_reader :cocina_file, :version, :druid

    delegate :filename, to: :cocina_file

    def render?
      cocina_file.administrative.sdrPreserve && @has_been_accessioned
    end
  end
end
