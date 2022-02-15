# frozen_string_literal: true

module Contents
  # Displays external files for a virtual object
  # e.g. https://argo.stanford.edu/view/druid:tm280sk2404
  class ExternalFileComponent < ViewComponent::Base
    with_collection_parameter :druid

    def initialize(druid:)
      @druid = druid
    end

    attr_reader :druid
  end
end
