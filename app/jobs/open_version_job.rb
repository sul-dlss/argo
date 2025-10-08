# frozen_string_literal: true

# Job to open a new version for objects
class OpenVersionJob < BulkActionJob
  def description
    params['version_description']
  end

  class OpenVersionJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      return failure!(message: "State isn't openable") unless VersionService.openable?(druid:)

      VersionService.open(druid:,
                          description:,
                          opening_user_name: user)
      success!(message: 'Version successfully opened')
    end

    delegate :description, to: :job
  end

  ##
  # A job that allows a user to specify a list of druids of objects to open
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required because groups are not persisted with the user.
  # @option params [Array] :user the user
  # @option params [String] :version_description
  # def perform(bulk_action_id, params)
  #   super

  #   description = params['version_description']

  #   with_items(params[:druids], name: 'Open version', check_update_ability: true) do |cocina_object, success, failure|
  #     next failure.call("State isn't openable") unless VersionService.openable?(druid: cocina_object.externalIdentifier)

  #     VersionService.open(druid: cocina_object.externalIdentifier,
  #                         description:,
  #                         opening_user_name: @current_user.to_s)
  #     success.call('Version successfully opened')
  #   end
  # end
end
