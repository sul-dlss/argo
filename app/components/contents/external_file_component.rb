# frozen_string_literal: true

module Contents
  # Displays external files for a virtual object
  # e.g. https://argo.stanford.edu/view/druid:tm280sk2404
  class ExternalFileComponent < ViewComponent::Base
    def initialize(external_file:)
      @resource_id, @filename = external_file.split('/')
    end

    attr_reader :resource_id, :filename

    def druid
      druid, = resource_id.split('_')
      "druid:#{druid}"
    end
  end
end
