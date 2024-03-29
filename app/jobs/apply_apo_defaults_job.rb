# frozen_string_literal: true

##
# job to apply APO defaults to a set of items
class ApplyApoDefaultsJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_items(params[:druids], name: 'Apply defaults') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      cocina_object = open_new_version_if_needed(cocina_object, version_message)

      Dor::Services::Client.object(cocina_object.externalIdentifier).apply_admin_policy_defaults
      success.call('Successfully applied defaults')
    end
  end

  private

  def version_message
    'Apply admin policy defaults'
  end
end
