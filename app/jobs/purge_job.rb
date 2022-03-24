# frozen_string_literal: true

##
# job to purge unpublished objects
class PurgeJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_items(params[:druids], name: 'Purge') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:manage_item, cocina_object)

      next failure.call('Cannot purge item because it has already been submitted') if WorkflowService.submitted?(druid: cocina_object.externalIdentifier)

      PurgeService.purge(druid: cocina_object.externalIdentifier)

      success.call('Purge sucessful')
    end
  end
end
