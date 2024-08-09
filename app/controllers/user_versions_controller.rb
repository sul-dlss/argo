# frozen_string_literal: true

class UserVersionsController < ApplicationController
  before_action :find_user_version_cocina
  load_and_authorize_resource :cocina, parent: false, except: %i[show]

  def show
    authorize! :read, @cocina

    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @cocina).render }
    end
  end

  def withdraw
    update_withdrawn(withdrawn: true)
    redirect_to item_user_version_path(druid_param, user_version_param),
                notice: 'Withdrawn. Purl will no longer display this version.'
  end

  def restore
    update_withdrawn(withdrawn: false)
    redirect_to item_user_version_path(druid_param, user_version_param),
                notice: 'Restored. Purl will display this version.'
  end

  def edit_move
    @druid = druid_param
    @user_versions_presenter = UserVersionsPresenter.new(user_version_view: user_version_param, user_version_inventory: client.inventory)
  end

  def move
    client.update(user_version: Dor::Services::Client::UserVersion::Version.new(userVersion: user_version_param, version: params[:version]))

    redirect_to item_user_version_path(druid_param, user_version_param),
                notice: 'Moved user version.'
  end

  private

  def druid_param
    params[:item_id]
  end

  def user_version_param
    params[:user_version_id]
  end

  def find_user_version_cocina
    @cocina = Repository.find_user_version(druid_param, user_version_param)
  end

  def update_withdrawn(withdrawn:)
    client.update(user_version: Dor::Services::Client::UserVersion::Version.new(withdrawn:, userVersion: user_version_param))
  end

  def client
    Dor::Services::Client.object(druid_param).user_version
  end
end
