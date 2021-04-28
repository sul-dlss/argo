# frozen_string_literal: true

class EmbargosController < ApplicationController
  before_action :load_and_authorize_resource

  def edit
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    raise ArgumentError, 'Missing embargo_date parameter' if params[:embargo_date].blank?

    begin
      params[:embargo_date].to_date
    rescue Date::Error
      return redirect_to solr_document_path(@cocina.externalIdentifier),
                         flash: { error: 'Invalid date' }
    end

    change_set = ItemChangeSet.new(@cocina)
    change_set.validate(embargo_release_date: params[:embargo_date])
    change_set.save

    respond_to do |format|
      format.any { redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Embargo was successfully updated' }
    end
  end

  private

  def load_and_authorize_resource
    @cocina = maybe_load_cocina(params[:item_id])

    authorize! :manage_item, @cocina
  end
end
