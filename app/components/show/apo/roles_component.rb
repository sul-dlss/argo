# frozen_string_literal: true

module Show
  module Apo
    class RolesComponent < ApplicationComponent
      # @param [ArgoShowPresenter] presenter
      def initialize(presenter:)
        @presenter = presenter
      end

      def permissions
        manage_permissions + view_permissions
      end

      private

      def model
        @presenter.item
      end

      def manage_permissions
        manage_role = model.roles&.find { |role| role.name == 'dor-apo-manager' }
        managers = manage_role ? manage_role.members.map { |member| "#{member.type}:#{member.identifier}" } : []
        build_permissions(managers, 'manage')
      end

      def view_permissions
        view_role = model.roles&.find { |role| role.name == 'dor-apo-viewer' }
        viewers = view_role ? view_role.members.map { |member| "#{member.type}:#{member.identifier}" } : []
        build_permissions(viewers, 'view')
      end

      def build_permissions(role_list, access)
        role_list.map do |name|
          if name.starts_with? 'workgroup:'
            { name: name.sub(/^workgroup:[^:]*:/, ''), type: 'group', access: access }
          else
            { name: name.sub(/^sunetid:/, ''), type: 'person', access: access }
          end
        end
      end
    end
  end
end
