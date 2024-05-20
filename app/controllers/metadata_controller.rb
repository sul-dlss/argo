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

  private

  def cocina
    Repository.find(params[:item_id])
  end
end
