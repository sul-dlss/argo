# frozen_string_literal: true

# Shows the raw xml of the workflow status, with pretty formatting
class WorkflowXmlPresenter
  def initialize(xml:)
    @xml = xml
  end

  def pretty_xml
    # rubocop:disable Rails/OutputSafety
    CodeRay::Duo[:xml, :div].highlight(Nokogiri::XML(xml).prettify).html_safe
    # rubocop:enable Rails/OutputSafety
  end

  private

  attr_reader :xml
end
