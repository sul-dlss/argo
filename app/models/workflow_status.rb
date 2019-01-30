# frozen_string_literal: true

# Represents the status of an item in the workflow
class WorkflowStatus
  # @param [String] pid
  # @param [String] workflow_name
  # @param [String] status_xml the xml from the workflow service for this object/workflow_name
  # @param [Dor::WorkflowObject] workflow_definition the definition of the workflow
  def initialize(pid:, workflow_name:, status_xml:, workflow_definition:)
    @pid = pid
    @workflow_name = workflow_name
    @status_xml = status_xml
    @workflow_definition = workflow_definition
  end

  attr_reader :workflow_name

  def empty?
    ng_xml.xpath('/workflow/process').empty?
  end

  def process_statuses
    return [] if empty?

    workflow_steps.map do |process|
      nodes = ng_xml.xpath("/workflow/process[@name = '#{process.name}']")
      node = nodes.max { |a, b| a.attr('version') <=> b.attr('version') }
      attributes = node ? Hash[node.attributes.collect { |k, v| [k.to_sym, v.value] }] : {}
      WorkflowProcessStatus.new(parent: self, name: process.name, **attributes)
    end
  end

  private

  attr_reader :workflow_definition, :status_xml

  def ng_xml
    @ng_xml ||= Nokogiri::XML(status_xml)
  end

  def workflow_steps
    workflow_definition.definition.processes
  end
end
