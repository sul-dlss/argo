# frozen_string_literal: true

##
# job to move an object to a new governing APO
class SetGoverningApoJob < BulkActionJob
  def new_apo_id
    params['new_apo_id']
  end

  class SetGoverningApoJobItem < BulkActionJobItem
    delegate :new_apo_id, to: :job

    def perform
      return failure!(message: "User not authorized to move item to #{new_apo_id}") unless can_manage?

      open_new_version_if_needed!(description: 'Updated governing APO')
      change_set.validate(admin_policy_id: new_apo_id)
      change_set.save
      close_version_if_needed!

      success!(message: 'Governing APO updated')
    end

    private

    def change_set
      @change_set ||= ItemChangeSet.new(cocina_object)
    end

    def can_manage?
      ability.can?(:manage_governing_apo, cocina_object, new_apo_id)
    end
  end
end
