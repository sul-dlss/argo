# frozen_string_literal: true

class DorObjectWorkflowStatus
  attr_reader :pid

  ##
  # @param [String] pid in format "druid:abc123def4567"
  def initialize(pid)
    @pid = pid
  end

  ##
  # @return [Boolean]
  def can_open_version?
    return false unless workflow.lifecycle('dor', pid, 'accessioned')
    return false if workflow.active_lifecycle('dor', pid, 'submitted')
    return false if workflow.active_lifecycle('dor', pid, 'opened')

    true
  end

  private

  def workflow
    Dor::Config.workflow.client
  end
end
