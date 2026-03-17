# frozen_string_literal: true

class UserVersionsController < ApplicationController
  before_action :load_cocina_object_user_version
  authorize_resource :cocina_object, parent: false, id_param: 'item_id'

  def show
    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @cocina_object).render }
    end
  end

  def withdraw
    update_user_version(withdrawn: true)
    redirect_to item_public_version_path(params[:item_id], params[:user_version_id]),
                notice: 'Withdrawn. Purl will no longer display this version.'
  end

  def restore
    update_user_version(withdrawn: false)
    redirect_to item_public_version_path(params[:item_id], params[:user_version_id]),
                notice: 'Restored. Purl will display this version.'
  end

  private

  def load_cocina_object_user_version
    @cocina_object = Repository.find_user_version(params[:item_id], params[:user_version_id])
  end

  def update_user_version(withdrawn:)
    client = Dor::Services::Client.object(params[:item_id]).user_version
    client.update(user_version: Dor::Services::Client::UserVersion::Version.new(withdrawn:, userVersion: params[:user_version_id]))
  end
end
