# frozen_string_literal: true

# Draws the form for managing a release. The form kicks off a bulk action.
class ManageReleasesController < ApplicationController
  include Blacklight::SearchHelper

  def show
    authorize! :manage_item, Dor.find(params[:item_id])
    _, @document = fetch params[:item_id]
    @bulk_action = BulkAction.new

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end
end
