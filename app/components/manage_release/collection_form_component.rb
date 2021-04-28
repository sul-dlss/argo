# frozen_string_literal: true

module ManageRelease
  class CollectionFormComponent < ApplicationComponent
    def initialize(form:, current_user:)
      @form = form
      @current_user = current_user
    end

    attr_reader :form, :current_user
  end
end
