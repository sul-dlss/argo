# frozen_string_literal: true

class WorkflowGridComponent < ApplicationComponent
  # @param [Hash] data
  def initialize(data:)
    @data = data
  end

  def render?
    @data.present?
  end

  # @return [Array<Array>] returns a list of tuples with the name and the data
  def workflows
    @data.keys.sort
         .reject { |wf_name| Settings.inactive_workflows.include?(wf_name) }
         .map { |wf_name| [wf_name, @data[wf_name]] }
  end
end
