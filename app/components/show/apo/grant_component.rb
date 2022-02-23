# frozen_string_literal: true

module Show
  module Apo
    class GrantComponent < ApplicationComponent
      def initialize(grant:)
        @name = grant.fetch(:name)
        @access = grant.fetch(:access)
      end

      attr_reader :name, :access
    end
  end
end
