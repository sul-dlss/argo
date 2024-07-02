# frozen_string_literal: true

class MetadataController < ApplicationController
  # Shows the modal with the descriptive metadata from MODS. This is triggered by the "Description" button on
  # the item show page.
  def descriptive
    xml = PurlFetcher::Client::Mods.create(cocina:)
    @mods_display = ModsDisplay::Record.new(xml).mods_display_html

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def cocina
    if params.key?(:user_version_id)
      Repository.find_user_version(params[:item_id], params[:user_version_id])
    else
      Repository.find(params[:item_id])
    end
  end
end
