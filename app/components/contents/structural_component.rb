# frozen_string_literal: true

module Contents
  class StructuralComponent < ViewComponent::Base
    # @param [Cocina::Models::DroStructural] structural
    # @param [String] object_id the identifier of the object
    # @param [String] user_version the user version of the object
    # @param [Bool] viewable if true the user will be presented with a link to download files
    def initialize(structural:, object_id:, user_version:, viewable:)
      @structural = structural
      @viewable = viewable
      @object_id = object_id
      @user_version = user_version
    end

    attr_reader :structural, :object_id, :user_version

    def viewable?
      @viewable
    end

    def paginatable_array
      @paginatable_array ||= Kaminari.paginate_array(structural.contains).page(params[:page]).per(50)
    end

    def number_of_content_items
      return constituents.size if virtual_object?

      structural.contains.size
    end

    def label_for_content_items
      return 'Constituent' if virtual_object?

      'Resource'
    end

    def virtual_object?
      constituents.present?
    end

    def constituents
      @constituents ||= structural.hasMemberOrders.first&.members
    end
  end
end
