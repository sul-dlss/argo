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
    return false unless accessioned?
    return false if get_active_lifecycle('submitted')
    return false if get_active_lifecycle('opened')
    true
  end

  ##
  # @return [Boolean]
  def can_close_version?
    return true if get_active_lifecycle('opened') &&
                  !get_active_lifecycle('submitted')
    false
  end

  ##
  # @return [Boolean]
  def published?
    return true if get_lifecycle('published')
    false
  end

  ##
  # @return [Boolean]
  def submitted?
    return true if get_lifecycle('submitted')
    false
  end

  ##
  # @return [Boolean]
  def accessioned?
    return true if get_lifecycle('accessioned')
    false
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
