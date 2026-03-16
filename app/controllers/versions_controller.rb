# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_cocina_object_version, only: :show
  load_resource :cocina_object, parent: false, class: 'Repository', id_param: 'item_id', except: :show
  authorize_resource :cocina_object, parent: false, id_param: 'item_id'

  def show
    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @cocina_object).render }
    end
  end

  def open_ui
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def close_ui
    versions = Dor::Services::Client.object(params[:item_id]).version.inventory
    current_version = versions.max_by(&:versionId)
    @description = current_version.message

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def open
    begin
      VersionService.open(druid: @cocina_object.externalIdentifier,
                          description: params[:description],
                          opening_user_name: current_user.to_s)
    rescue Dor::Services::Client::UnexpectedResponse => e
      return redirect_to solr_document_path(params[:item_id]), alert: e.message
    end
    msg = "#{@cocina_object.externalIdentifier} is open for modification!"
    redirect_to solr_document_path(params[:item_id]), notice: msg
    Dor::Services::Client.object(@cocina_object.externalIdentifier).reindex
  end

  # as long as this isn't a bulk operation, and we get description
  # values, update it in the version service
  def close
    VersionService.close(
      druid: @cocina_object.externalIdentifier,
      description: params[:description],
      user_name: current_user.to_s
    )
    msg = "Version #{@cocina_object.version} of #{@cocina_object.externalIdentifier} has been closed!"
    redirect_to solr_document_path(params[:item_id]), notice: msg
    Dor::Services::Client.object(@cocina_object.externalIdentifier).reindex
  end

  private

  def load_cocina_object_version
    @cocina_object = Repository.find_version(params[:item_id], params[:version_id])
  end
end
