# frozen_string_literal: true

module Contents
  class ResourceComponent < ViewComponent::Base
    def initialize(resource:, resource_counter:, viewable:)
      @resource = resource
      @resource_counter = resource_counter
      @viewable = viewable
    end

    attr_reader :resource, :resource_counter

    def viewable?
      @viewable
    end

    def type
      # TODO: resource type will be in the metadata
      resource.type.delete_prefix('http://cocina.sul.stanford.edu/models/').delete_suffix('.jsonld')
    end

    delegate :label, to: :resource

    def files
      resource.structural.contains
    end
  end
end
