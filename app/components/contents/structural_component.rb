# frozen_string_literal: true

module Contents
  class StructuralComponent < ViewComponent::Base
    def initialize(item:, viewable:)
      @item = item
      @viewable = viewable
      @object_id = item.id
    end

    attr_reader :item, :object_id

    def viewable?
      @viewable
    end
  end
end
