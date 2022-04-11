# frozen_string_literal: true

module Contents
  class StructuralComponent < ViewComponent::Base
    # @param [Cocina::Models::DroStructural] structural
    # @param [String] object_id the identifier of the object
    # @param [Bool] viewable if true the user will be presented with a link to download files
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
