# frozen_string_literal: true

# Draws the form for managing a release. The form kicks off a bulk action.
class ManageReleasesController < ApplicationController
  include Blacklight::Searchable

  def show
    cocina = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, cocina
    _, @document = search_service.fetch params[:item_id]
    @bulk_action = BulkAction.new

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end
end
