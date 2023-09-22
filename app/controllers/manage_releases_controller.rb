# frozen_string_literal: true

# Draws the form for managing a release. The form kicks off a bulk action.
class ManageReleasesController < ApplicationController
  include Blacklight::Searchable

  def show
    cocina = Repository.find(params[:item_id])
    authorize! :update, cocina
    @document = search_service.fetch(params[:item_id])
    @bulk_action = BulkAction.new

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end
end
