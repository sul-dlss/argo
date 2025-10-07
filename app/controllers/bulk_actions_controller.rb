# frozen_string_literal: true

class BulkActionsController < ApplicationController
  include Blacklight::SearchContext

  before_action :set_bulk_action, only: %i[destroy file]

  # GET /bulk_actions
  def index
    @bulk_actions = BulkAction.where(user: current_user).order(created_at: :desc)
  end

  # GET /bulk_actions/new
  def new; end

  # DELETE /bulk_actions/1
  def destroy
    @bulk_action.destroy
    redirect_to bulk_actions_url, notice: 'Bulk action was deleted.'
  end

  # GET /bulk_actions/1/file
  def file
    send_file(@bulk_action.file(params[:filename])) if @bulk_action.present?
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bulk_action
    @bulk_action = current_user.bulk_actions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: 'Object Not Found', status: :not_found
  end
end
