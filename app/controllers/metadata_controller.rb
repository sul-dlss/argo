# frozen_string_literal: true

class MetadataController < ApplicationController
  def descriptive
    xml = metadata_service.descriptive
    @mods_display = ModsDisplay::Record.new(xml).mods_display_html

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  Field = Struct.new(:name, :value)

  def full_dc
    dc_xml = Nokogiri::XML(metadata_service.dublin_core)
    nodes = dc_xml.xpath('/oai_dc:dc/*', oai_dc: 'http://www.openarchives.org/OAI/2.0/oai_dc/')
    @fields = nodes.map { |node| Field.new(node.name.humanize, node.text) }

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def metadata_service
    @metadata_service ||= Dor::Services::Client.object(params[:item_id]).metadata
  end
end
