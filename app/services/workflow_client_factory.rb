# frozen_string_literal: true

# This initializes the workflow client with values from settings
class WorkflowClientFactory
  def self.build
    logger = Rails.logger
    Dor::Workflow::Client.new(url: Settings.workflow_url, logger:, timeout: Settings.workflow.timeout)
  end
end
