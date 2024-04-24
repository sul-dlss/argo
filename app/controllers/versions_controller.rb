# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_and_authorize_resource

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
    VersionService.open(druid: @cocina_object.externalIdentifier,
                        description: params[:description],
                        opening_user_name: current_user.to_s)
    msg = "#{@cocina_object.externalIdentifier} is open for modification!"
    redirect_to solr_document_path(params[:item_id]), notice: msg
    Dor::Services::Client.object(@cocina_object.externalIdentifier).reindex
  rescue StandardError => e
    raise e unless e.to_s == 'Object net yet accessioned'

    render status: :internal_server_error, plain: 'Object net yet accessioned'
    nil
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

  def load_and_authorize_resource
    @cocina_object = Repository.find(params[:item_id])
    authorize! :update, @cocina_object
  end
end
