# frozen_string_literal: true

# Shows the raw xml of the workflow status, with pretty formatting
class WorkflowXmlPresenter
  def initialize(xml:)
    @xml = xml
  end

  def pretty_xml
    CodeRay::Duo[:xml, :div].highlight(PrettyXml.print(xml)).html_safe
  end

  private

  attr_reader :xml
end
