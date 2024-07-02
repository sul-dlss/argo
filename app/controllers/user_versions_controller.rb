# frozen_string_literal: true

class UserVersionsController < ApplicationController
  before_action :find_user_version_cocina
  load_and_authorize_resource :cocina, parent: false

  def show
    respond_to do |format|
      format.json { render json: CocinaHashPresenter.new(cocina_object: @cocina).render }
    end
  end

  private

  def find_user_version_cocina
    @cocina = Repository.find_user_version(params[:item_id], params[:id])
  end
end
