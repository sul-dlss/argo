# frozen_string_literal: true

##
# job to apply APO defaults to a set of items
class ApplyApoDefaultsJob < BulkActionJob
  class ApplyApoDefaultsJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      open_new_version_if_needed!(description: 'Applied admin policy defaults')

      Dor::Services::Client.object(druid).apply_admin_policy_defaults

      close_version_if_needed!
      success!(message: 'Successfully applied defaults')
    end
  end
end
