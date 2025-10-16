# frozen_string_literal: true

##
# job to purge unpublished objects
class PurgeJob < BulkActionJob
  class PurgeJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      if WorkflowService.submitted?(druid:)
        return failure!(message: 'Cannot purge item because it has already been submitted')
      end

      PurgeService.purge(druid:, user_name: user)

      success!(message: 'Purge sucessful')
    end
  end
end
