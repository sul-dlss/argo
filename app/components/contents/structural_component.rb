# frozen_string_literal: true

module Contents
  class StructuralComponent < ViewComponent::Base
    def initialize(structural:, object_id:, viewable:)
      @structural = structural
      @viewable = viewable
      @object_id = object_id
    end

    attr_reader :structural, :object_id

    def viewable?
      @viewable
    end
  end
end
