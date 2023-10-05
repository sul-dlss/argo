# frozen_string_literal: true

module Contents
  class ResourceComponent < ViewComponent::Base
    def initialize(resource:, resource_counter:, counter_offset:, object_id:, viewable:)
      @resource = resource
      @resource_counter = resource_counter + counter_offset
      @object_id = object_id
      @viewable = viewable
    end

    attr_reader :resource, :resource_counter, :object_id

    def viewable?
      @viewable
    end

    def image?
      type == 'image'
    end

    def type
      resource.type.delete_prefix('https://cocina.sul.stanford.edu/models/resources/')
    end

    delegate :label, to: :resource

    def files
      resource.structural.contains
    end
  end
end
