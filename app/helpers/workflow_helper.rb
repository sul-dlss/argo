# frozen_string_literal: true

module WorkflowHelper
  # Workflows that can be set for an APO.
  # @return [Array<Array<String, String>] array suitable for select_tag options
  def workflow_options(except: [])
    # per https://github.com/sul-dlss/argo/issues/3741, this should be hardcoded
    %w[
      accessionWF
      gisAssemblyWF
      gisDeliveryWF
      goobiWF
      registrationWF
      wasCrawlDisseminationWF
      wasCrawlPreassemblyWF
      wasSeedPreassemblyWF
    ].reject { |workflow| except.include?(workflow) }.map do |workflow|
      [workflow, workflow]
    end
  end

  # Workflows that can be started by a user.
  # @return [Array<Array<String, String>] array suitable for select_tag options
  def start_workflow_options
    workflow_options(except: %w[accessionWF registrationWF])
  end
end
