# frozen_string_literal: true

class StateService
  # having version is preferred as without it, a call to
  # fedora will be made to retrieve it.
  def initialize(pid, version:)
    @pid = pid
    @version = version
  end

  def allows_modification?
    !client.lifecycle('dor', pid, 'submitted') ||
      client.active_lifecycle('dor', pid, 'opened', version: version)
  end

  private

  attr_reader :pid, :version

  def client
    Dor::Config.workflow.client
  end
end
