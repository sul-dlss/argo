# frozen_string_literal: true

class StateService
  # having version is preferred as without it, a call to
  # fedora will be made to retrieve it.
  def initialize(pid, version:)
    @pid = pid
    @version = version
  end

  def allows_modification?
    !client.lifecycle(druid: pid, milestone_name: 'submitted') ||
      client.active_lifecycle(druid: pid, milestone_name: 'opened', version: version)
  end

  private

  attr_reader :pid, :version

  def client
    WorkflowClientFactory.build
  end
end
