# frozen_string_literal: true

##
# Job to update rights for objects
class SetRightsJob < GenericJob
  ##
  # A job that allows a user to update the rights for a list of druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  def perform(bulk_action_id, params)
    super

    access_params = params.slice(:view_access, :download_access, :controlled_digital_lending, :access_location)
    raise "Must provide rights" if access_params.blank?

    with_items(params[:druids], name: "Set rights") do |cocina_object, success, failure|
      next failure.call("Not authorized") unless ability.can?(:update, cocina_object)

      state_service = StateService.new(cocina_object)
      next failure.call("Object cannot be modified in its current state.") unless state_service.allows_modification?

      change_set = if cocina_object.collection?
        # Collection only allows setting view access to dark or world
        view_access = access_params[:view_access] == "dark" ? "dark" : "world"
        access_params = {view_access:}
        CollectionChangeSet.new(cocina_object)
      else
        ItemChangeSet.new(cocina_object)
      end

      change_set.validate(**access_params)
      change_set.save

      success.call("Successfully updated rights")
    end
  end
end
