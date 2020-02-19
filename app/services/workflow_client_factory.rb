# frozen_string_literal: true

# This initializes the workflow client with values from settings
class WorkflowClientFactory
  def self.build
    logger = Logger.new(Settings.workflow.logfile, Settings.workflow.shift_age)
    Dor::Workflow::Client.new(url: Settings.workflow_url, logger: logger, timeout: Settings.workflow.timeout)
  end
end
