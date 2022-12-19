# frozen_string_literal: true

module Show
  module Item
    module Structure
      class FileHierarchyComponent < ViewComponent::Base
        # @params [String] view_token
        def initialize(view_token:)
          @view_token = view_token
        end

        attr_reader :view_token
      end
    end
  end
end
