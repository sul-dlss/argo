# frozen_string_literal: true

module Show
  class ProjectTagComponent < ApplicationComponent
    def initialize(change_set:)
      @change_set = change_set
    end

    delegate :id, :project, to: :@change_set
  end
end
