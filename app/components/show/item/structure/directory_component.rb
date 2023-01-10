# frozen_string_literal: true

module Show
  module Item
    module Structure
      class DirectoryComponent < ViewComponent::Base
        def initialize(directory:)
          @directory = directory
        end

        delegate :name, :children_directories, :children_files, :index, to: :directory

        attr_reader :directory
      end
    end
  end
end
