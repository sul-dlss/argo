# frozen_string_literal: true

##
# Job to close objects
class CloseVersionJob < BulkActionJob
  class CloseVersionJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      VersionService.close(druid: druid)
      success!(message: 'Object successfully closed')
    end
  end
end
