# frozen_string_literal: true

module Contents
  class ResourceComponent < ViewComponent::Base
    def initialize(resource:, resource_counter:, object_id:, viewable:)
      @resource = resource
      @resource_counter = resource_counter
      @object_id = object_id
      @viewable = viewable
    end

    attr_reader :resource, :resource_counter, :object_id

    def viewable?
      @viewable
    end

    def type
      resource.type.delete_prefix('http://cocina.sul.stanford.edu/models/resources/').delete_suffix('.jsonld')
    end

    delegate :label, to: :resource

    def files
      resource.structural.contains
    end
  end
end
