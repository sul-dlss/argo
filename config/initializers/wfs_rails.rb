if Settings.WFS_RAILS.ENABLE
  booted_url = Capybara::Discoball::Runner.new(OpenStruct.new(new: WfsRails::Engine.app)).boot
  # Reconfigure Dor::WorkflowService with booted_url of WfsRails
  Dor::WorkflowService.configure booted_url, { logger: Logger.new(Settings.WORKFLOW.LOGFILE) }
  Dor::Config.workflow.url = booted_url
  Settings.WORKFLOW_URL = booted_url
end
