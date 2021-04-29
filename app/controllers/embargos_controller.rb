# frozen_string_literal: true

class EmbargosController < ApplicationController
  before_action :load_and_authorize_resource

  def new
    @change_set = change_set_class.new(@cocina)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def edit
    @change_set = change_set_class.new(@cocina)

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def update
    begin
      update_params[:embargo_release_date].to_date
    rescue Date::Error
      return redirect_to solr_document_path(@cocina.externalIdentifier),
                         flash: { error: 'Invalid date' }
    end

    change_set = change_set_class.new(@cocina)
    change_set.validate(update_params)
    change_set.save
    Argo::Indexer.reindex_pid_remotely(@cocina.externalIdentifier)

    respond_to do |format|
      format.any { redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Embargo was successfully updated' }
    end
  end

  private

  def change_set_class
    ItemChangeSet
  end

  def load_and_authorize_resource
    @cocina = maybe_load_cocina(params[:item_id])

    authorize! :manage_item, @cocina
  end

  def update_params
    params.require(change_set_class.model_name.param_key).permit(:embargo_release_date, :embargo_access)
  end
end
