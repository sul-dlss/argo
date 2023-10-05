# frozen_string_literal: true

class MetadataController < ApplicationController
  # Shows the modal with the MODS XML. This is triggered by the "MODS" button on
  # the item show page.
  def descriptive
    xml = ModsService.new(cocina).to_xml
    @mods_display = ModsDisplay::Record.new(xml).mods_display_html

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  Field = Struct.new(:name, :value)

  def full_dc_xml
    @content = PrettyXml.print(dublin_core.to_xml)
    render layout: !request.xhr?
  end

  def full_dc
    nodes = dublin_core.xpath('/oai_dc:dc/*', oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/')
    @fields = nodes.map { |node| Field.new(node.name.humanize, node.text) }

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def cocina
    Repository.find(params[:item_id])
  end

  def dublin_core
    desc_md_xml = ModsService.new(cocina).ng_xml(include_access_conditions: false)
    DublinCoreService.new(desc_md_xml).ng_xml
  end
end
