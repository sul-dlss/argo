# frozen_string_literal: true

class EmbargosController < ApplicationController
  before_action :load_and_authorize_resource

  def new
    @change_set = EmbargoForm.new(@cocina)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def edit
    @change_set = EmbargoForm.new(@cocina)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    begin
      update_params[:release_date].to_date
    rescue Date::Error
      return redirect_to solr_document_path(@cocina.externalIdentifier),
                         flash: { error: 'Invalid date' }
    end

    change_set = EmbargoForm.new(@cocina)
    change_set.validate(update_params)
    change_set.save
    Argo::Indexer.reindex_druid_remotely(@cocina.externalIdentifier)

    respond_to do |format|
      format.any { redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Embargo was successfully updated' }
    end
  end

  private

  def load_and_authorize_resource
    @cocina = Repository.find(params[:item_id])

    authorize! :update, @cocina
  end

  def update_params
    params.require(EmbargoForm.model_name.param_key).permit(:release_date, :view_access, :download_access, :access_location)
  end
end
