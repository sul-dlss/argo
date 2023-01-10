# frozen_string_literal: true

module Show
  module Item
    module Structure
      class FileComponent < ViewComponent::Base
        def initialize(file:)
          @file = file
        end

        delegate :name, :size, :index, to: :file

        attr_reader :file
      end
    end
  end
end
