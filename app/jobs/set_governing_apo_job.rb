# frozen_string_literal: true

##
# job to move an object to a new governing APO
class SetGoverningApoJob < GenericJob
  attr_reader :new_apo_id

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [String] :new_apo_id
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @new_apo_id = params['new_apo_id']

    with_items(params[:druids], name: 'Set governing APO') do |cocina_item, success, failure|
      next failure.call("user not authorized to move item to #{new_apo_id}") unless ability.can?(:manage_governing_apo, cocina_item, new_apo_id)

      state_service = StateService.new(cocina_item)
      open_new_version(cocina_item.externalIdentifier, cocina_item.version, 'Set new governing APO') unless state_service.allows_modification?

      change_set = ItemChangeSet.new(Item.new(cocina_item))
      change_set.validate(admin_policy_id: new_apo_id)
      change_set.save
      success.call('Governing APO updated')
    end
  end
end
