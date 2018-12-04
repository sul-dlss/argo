# frozen_string_literal: true

class BulkActionsController < ApplicationController
  before_action :set_bulk_action, only: [:destroy, :file]

  rescue_from ActiveRecord::RecordNotFound, with: -> { render plain: 'Record Not Found', status: :not_found }

  # GET /bulk_actions
  def index
    @bulk_actions = BulkAction.where(user: current_user).order('created_at DESC')
  end

  # GET /bulk_actions/new
  def new
    @bulk_action = BulkAction.new
    @last_search = session[:search].present? ? searches_from_history.find(session[:search]['id']) : searches_from_history.first
  end

  # POST /bulk_actions
  def create
    # Since the groups aren't persisted, we need to pass them here.
    @bulk_action = BulkAction.new(
      bulk_action_params.merge(user: current_user, groups: current_user.groups)
    )

    if @bulk_action.save
      redirect_to action: :index, notice: 'Bulk action was successfully created.'
    else
      render :new
    end
  end

  # DELETE /bulk_actions/1
  def destroy
    @bulk_action.destroy
    redirect_to bulk_actions_url, notice: 'Bulk action was successfully destroyed.'
  end

  # GET /bulk_actions/1/file
  def file
    send_file(@bulk_action.file(params[:filename]), type: params[:mime_type]) if @bulk_action.present?
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bulk_action
    @bulk_action = current_user.bulk_actions.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def bulk_action_params
    params.require(:bulk_action).permit(
      :action_type,
      :description,
      :pids,
      manage_release: [:tag, :what, :who, :to],
      set_governing_apo: [:new_apo_id]
    )
  end
end
