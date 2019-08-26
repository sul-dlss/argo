# frozen_string_literal: true

module Argo
  class Ability
    class << self
      def can_manage_items?(roles)
        intersect roles, groups_which_manage_items
      end

      def can_edit_desc_metadata?(roles)
        intersect roles, groups_which_edit_desc_metadata
      end

      def can_view?(roles)
        intersect roles, groups_which_view
      end

      private

      def groups_which_manage_items
        %w[dor-administrator sdr-administrator dor-apo-manager dor-apo-depositor]
      end

      def groups_which_edit_desc_metadata
        groups_which_manage_items + %w[dor-apo-metadata]
      end

      def groups_which_view
        groups_which_manage_items + %w[dor-viewer sdr-viewer]
      end

      def intersect(arr1, arr2)
        (arr1 & arr2).length > 0
      end
    end
  end
end
