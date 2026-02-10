# frozen_string_literal: true

module Contents
  class ResourceComponent < ViewComponent::Base
    def initialize(resource:, resource_counter:, counter_offset:, item_id:, user_version:, viewable:) # rubocop:disable Metrics/ParameterLists
      @resource = resource
      @resource_counter = resource_counter + counter_offset
      @item_id = item_id
      @user_version = user_version
      @viewable = viewable
    end

    attr_reader :resource, :resource_counter, :item_id, :user_version

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
