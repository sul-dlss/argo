# frozen_string_literal: true

##
# job to purge unpublished objects
class PurgeJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_items(params[:druids], name: 'Purge') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      if WorkflowService.submitted?(druid: cocina_object.externalIdentifier)
        next failure.call('Cannot purge item because it has already been submitted')
      end

      PurgeService.purge(druid: cocina_object.externalIdentifier, user_name: @current_user.login)

      success.call('Purge sucessful')
    end
  end
end
