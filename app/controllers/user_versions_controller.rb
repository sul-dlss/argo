# frozen_string_literal: true

class UserVersionsController < ApplicationController
  before_action :find_user_version_cocina
  load_and_authorize_resource :cocina, parent: false

  def show
    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @cocina).render }
    end
  end

  def withdraw
    update_user_version(withdrawn: true)
    redirect_to item_user_version_path(druid_param, user_version_param),
                notice: 'Withdrawn. Purl will no longer display this version.'
  end

  def restore
    update_user_version(withdrawn: false)
    redirect_to item_user_version_path(druid_param, user_version_param),
                notice: 'Restored. Purl will display this version.'
  end

  private

  def druid_param
    params[:item_id]
  end

  def user_version_param
    params[:id] || params[:user_version_id]
  end

  def find_user_version_cocina
    @cocina = Repository.find_user_version(druid_param, user_version_param)
  end

  def update_user_version(withdrawn:)
    client = Dor::Services::Client.object(druid_param).user_version
    client.update(user_version: Dor::Services::Client::UserVersion::Version.new(withdrawn:, userVersion: user_version_param))
  end
end
