class BulkActionsController < ApplicationController
  before_action :set_bulk_action, only: [:destroy]
  rescue_from ActiveRecord::RecordNotFound, with: -> { render text: 'Record Not Found', status: :not_found }

  # GET /bulk_actions
  def index
    @bulk_actions = BulkAction.where(user: current_user).order('created_at DESC')
  end

  # GET /bulk_actions/new
  def new
    @bulk_action = BulkAction.new
  end

  # POST /bulk_actions
  def create
    @bulk_action = BulkAction.new(bulk_action_params)
    @bulk_action.user = current_user

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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bulk_action
    @bulk_action = current_user.bulk_actions.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def bulk_action_params
    params.require(:bulk_action).permit(:action_type, :description)
  end
end
