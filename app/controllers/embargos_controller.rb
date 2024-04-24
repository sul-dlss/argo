# frozen_string_literal: true

class EmbargosController < ApplicationController
  load_and_authorize_resource :cocina, parent: false, class: 'Repository', id_param: 'item_id', only: %i[edit update]

  def new
    cocina = Repository.find(params[:item_id])
    authorize! :update, cocina
    @change_set = EmbargoForm.new(cocina)

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
    Dor::Services::Client.object(@cocina.externalIdentifier).reindex

    respond_to do |format|
      format.any do
        redirect_to solr_document_path(@cocina.externalIdentifier), notice: 'Embargo was successfully updated'
      end
    end
  end

  private

  def update_params
    params.require(EmbargoForm.model_name.param_key).permit(:release_date, :view_access, :download_access,
                                                            :access_location)
  end
end
