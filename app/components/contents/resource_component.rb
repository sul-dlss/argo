# frozen_string_literal: true

module Contents
  class ResourceComponent < ViewComponent::Base
    # @param [FileSet] resource
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

    def image?
      type == 'image'
    end

    def type
      resource.type.delete_prefix('https://cocina.sul.stanford.edu/models/resources/')
    end

    delegate :label, :files, to: :resource
  end
end
