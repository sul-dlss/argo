# frozen_string_literal: true

module Contents
  class PreservationLinkComponent < ApplicationComponent
    def initialize(druid:, cocina_file:, version:)
      @druid = druid
      @cocina_file = cocina_file
      @version = version
    end

    attr_reader :cocina_file, :version, :druid

    delegate :filename, to: :cocina_file

    def render?
      version.present? && cocina_file.administrative.sdrPreserve
    end
  end
end
