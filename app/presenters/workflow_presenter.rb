# frozen_string_literal: true

class WorkflowPresenter
  # @param [Dor::Item] object
  # @param [String] workflow_name
  # @param [String] xml the workflow xml steps that this object has completed
  # @param [Array<Dor::Workflow::Process>] workflow_steps the xml that describes the definition of this workflow
  def initialize(object:, workflow_name:, xml:, workflow_steps:)
    @object = object
    @workflow_name = workflow_name
    @xml = xml
    @workflow_steps = workflow_steps
  end

  delegate :pid, to: :object
  attr_reader :workflow_name

  # This iterates over all the steps in the workflow definition and creates a presenter
  # for each of the most recent version.
  # @return [Array<Dor::Workflow::Process>]
  def processes
    return [] if empty?

    workflow_steps.collect do |process|
      nodes = ng_xml.xpath("/workflow/process[@name = '#{process.name}']")
      node = nodes.max { |a, b| a.attr('version') <=> b.attr('version') }
      process.update!(node, self)
    end
  end

  def pretty_xml
    # rubocop:disable Rails/OutputSafety
    CodeRay::Duo[:xml, :div].highlight(Nokogiri::XML(xml).prettify).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  private

  attr_reader :object, :xml, :workflow_steps

  def ng_xml
    @ng_xml ||= Nokogiri::XML(xml)
  end

  def empty?
    ng_xml.xpath('/workflow/process').empty?
  end
end
