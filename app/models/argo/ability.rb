# frozen_string_literal: true

module Argo
  class Ability
    class << self
      def can_manage_item?(roles)
        intersect roles, groups_which_manage_item
      end

      def can_manage_desc_metadata?(roles)
        intersect roles, groups_which_manage_desc_metadata
      end

      def can_manage_system_metadata?(roles)
        intersect roles, groups_which_manage_system_metadata
      end

      def can_manage_content?(roles)
        intersect roles, groups_which_manage_content
      end

      def can_manage_rights?(roles)
        intersect roles, groups_which_manage_rights
      end

      def can_manage_embargo?(roles)
        intersect roles, groups_which_manage_embargo
      end

      def can_view_content?(roles)
        intersect roles, groups_which_view_content
      end

      def can_view_metadata?(roles)
        intersect roles, groups_which_view_metadata
      end

      private

      def groups_which_manage_item
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor']
      end

      def groups_which_manage_desc_metadata
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-apo-metadata']
      end

      def groups_which_manage_system_metadata
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor']
      end

      def groups_which_manage_content
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor']
      end

      def groups_which_manage_rights
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor']
      end

      def groups_which_manage_embargo
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor']
      end

      def groups_which_view_content
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-viewer', 'sdr-viewer']
      end

      def groups_which_view_metadata
        ['dor-administrator', 'sdr-administrator', 'dor-apo-manager', 'dor-apo-depositor', 'dor-viewer', 'sdr-viewer']
      end

      def intersect(arr1, arr2)
        (arr1 & arr2).length > 0
      end
    end
  end
end
