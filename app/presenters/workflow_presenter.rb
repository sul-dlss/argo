# frozen_string_literal: true

class WorkflowPresenter
  def initialize(object:, workflow_name:, xml:)
    @object = object
    @workflow_name = workflow_name
    @xml = xml
  end

  delegate :pid, to: :object
  attr_reader :workflow_name

  # This is going to find the workflow definition:
  #   Dor::WorkflowObject.find_by_name(workflowId.first) and get the steps from there.
  #   then it will fill in process status with that found in the xml.
  # @return [Array<Dor::Workflow::Process>]
  def processes
    return [] if workflow_document.nil?

    workflow_document.processes
  end

  def pretty_xml
    # rubocop:disable Rails/OutputSafety
    CodeRay::Duo[:xml, :div].highlight(Nokogiri::XML(xml).prettify).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  private

  attr_reader :object, :xml

  def workflow_document
    @workflow_document ||= begin
      ng_xml = Nokogiri::XML(xml)
      return if ng_xml.xpath('workflow').empty?

      Dor::Workflow::Document.new(ng_xml.to_s)
    end
  end
end
