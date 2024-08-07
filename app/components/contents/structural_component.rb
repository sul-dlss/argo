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

    def number_of_file_sets
      structural.contains.size
    end
  end
end
