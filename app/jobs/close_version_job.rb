# frozen_string_literal: true

##
# Job to close objects
class CloseVersionJob < BulkActionJob
  class CloseVersionJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      close_version_if_needed!
      success!(message: 'Object successfully closed')
    end
  end
end
