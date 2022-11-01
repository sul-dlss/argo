# frozen_string_literal: true

##
# Job to close objects
class CloseVersionJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids of objects to close
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array] :user the user
  def perform(bulk_action_id, params)
    super

    with_items(params[:druids], name: "Close version") do |cocina_object, success, failure|
      next failure.call("Not authorized") unless ability.can?(:update, cocina_object)

      VersionService.close(identifier: cocina_object.externalIdentifier)
      success.call("Object successfully closed")
    end
  end
end
