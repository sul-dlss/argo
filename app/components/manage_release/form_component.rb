# frozen_string_literal: true

module ManageRelease
  class FormComponent < ApplicationComponent
    def initialize(bulk_action:, document:)
      @bulk_action = bulk_action
      @document = document
    end

    def child_form(form)
      case @document.object_type
      when 'collection'
        render CollectionFormComponent.new(form:, current_user: helpers.current_user)
      else
        render ItemFormComponent.new(form:, current_user: helpers.current_user)
      end
    end
  end
end
