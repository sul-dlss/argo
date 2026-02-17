# frozen_string_literal: true

class MetadataController < ApplicationController
  # Shows the modal with the descriptive metadata from MODS. This is triggered by the "Description" button on
  # the item show page.
  def descriptive
    @cocina_display = CocinaDisplay::CocinaRecord.new(CocinaDisplay::Utils.deep_compact_blank(cocina.as_json))

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def cocina
    if params.key?(:user_version_id)
      Repository.find_user_version(params[:item_id], params[:user_version_id])
    elsif params.key?(:version_id)
      Repository.find_version(params[:item_id], params[:version_id])
    else
      Repository.find(params[:item_id])
    end
  end
end
