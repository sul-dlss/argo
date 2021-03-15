# frozen_string_literal: true

module Contents
  class StructuralComponent < ViewComponent::Base
    def initialize(structural:, viewable:)
      @structural = structural
      @viewable = viewable
    end

    attr_reader :structural

    def viewable?
      @viewable
    end
  end
end
