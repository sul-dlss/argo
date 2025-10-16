# frozen_string_literal: true

# Job to open a new version for objects
class OpenVersionJob < BulkActionJob
  def description
    params['version_description']
  end

  class OpenVersionJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      return failure!(message: "State isn't openable") unless VersionService.openable?(druid:)

      VersionService.open(druid:,
                          description:,
                          opening_user_name: user)
      success!(message: 'Version successfully opened')
    end

    delegate :description, to: :job
  end
end
