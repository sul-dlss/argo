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

    new_rights = params[:rights]
    raise 'Must provide rights' if new_rights.blank?

    with_items(params[:druids], name: 'Set rights') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:manage_item, cocina_object)

      state_service = StateService.new(cocina_object.externalIdentifier, version: cocina_object.version)
      next failure.call('Object cannot be modified in its current state.') unless state_service.allows_modification?

      form_type = cocina_object.collection? ? CollectionRightsForm : DroRightsForm
      form = form_type.new(cocina_object)
      form.validate(rights: new_rights)
      form.save

      success.call('Successfully updated rights')
    end
  end
end
