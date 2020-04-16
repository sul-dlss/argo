# frozen_string_literal: true

class DorObjectWorkflowStatus
  attr_reader :pid, :version

  ##
  # @param [String] pid in format "druid:abc123def4567"
  def initialize(pid, version:)
    @pid = pid
    @version = version
  end

  ##
  # @return [Boolean]
  def can_open_version?
    return false unless workflow.lifecycle(druid: pid, milestone_name: 'accessioned')
    return false if workflow.active_lifecycle(druid: pid, milestone_name: 'submitted', version: version)
    return false if workflow.active_lifecycle(druid: pid, milestone_name: 'opened', version: version)

    true
  end

  private

  def workflow
    WorkflowClientFactory.build
  end
end
