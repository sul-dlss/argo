class DorObjectWorkflowStatus
  attr_reader :pid

  ##
  # @param [String] pid in format "druid:abc123def4567"
  def initialize(pid)
    @pid = pid
  end

  ##
  # @return [Boolean]
  def accessioned?
    get_lifecycle('accessioned') ? true : false
  end

  ##
  # @return [Boolean]
  def can_open_version?
    accessioned? && !(submitted_now? || opened_now?)
  end

  ##
  # @return [Boolean]
  def can_close_version?
    opened_now? && !submitted_now?
  end

  ##
  # @return [Boolean]
  def opened_now?
    get_active_lifecycle('opened') ? true : false
  end

  ##
  # @return [Boolean]
  def published?
    get_lifecycle('published') ? true : false
  end

  ##
  # @return [Boolean]
  def submitted?
    get_lifecycle('submitted') ? true : false
  end

  ##
  # @return [Boolean]
  def submitted_now?
    get_active_lifecycle('submitted') ? true : false
  end

  private

  def workflow
    Dor::Config.workflow.client
  end

  def get_lifecycle(task)
    workflow.get_lifecycle('dor', pid, task)
  end

  def get_active_lifecycle(task)
    workflow.get_active_lifecycle('dor', pid, task)
  end
end
