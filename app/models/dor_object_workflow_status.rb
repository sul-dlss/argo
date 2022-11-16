# frozen_string_literal: true

class DorObjectWorkflowStatus
  attr_reader :druid, :version

  ##
  # @param [String] druid in format "druid:abc123def4567"
  def initialize(druid, version:)
    @druid = druid
    @version = version
  end

  ##
  # @return [Boolean]
  def can_open_version?
    return false unless workflow.lifecycle(druid:, milestone_name: "accessioned")
    return false if workflow.active_lifecycle(druid:, milestone_name: "submitted", version:)
    return false if workflow.active_lifecycle(druid:, milestone_name: "opened", version:)

    true
  end

  private

  def workflow
    WorkflowClientFactory.build
  end
end
