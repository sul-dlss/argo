# frozen_string_literal: true

class BulkActionsController < ApplicationController
  include Blacklight::SearchContext

  before_action :set_bulk_action, only: %i[destroy file]

  rescue_from ActiveRecord::RecordNotFound, with: -> { render plain: 'Record Not Found', status: :not_found }

  # GET /bulk_actions
  def index
    @bulk_actions = BulkAction.where(user: current_user).order('created_at DESC')
  end

  # GET /bulk_actions/new
  def new
    @form = BulkActionForm.new(BulkAction.new, groups: current_user.groups)
    @last_search = session[:search].present? ? searches_from_history.find(session[:search]['id']) : searches_from_history.first
  end

  # POST /bulk_actions
  def create
    # Since the groups aren't persisted, we need to pass them here.
    @form = BulkActionForm.new(BulkAction.new(user: current_user), groups: current_user.groups)

    if @form.validate(bulk_action_params) && @form.save
      flash[:notice] = 'Bulk action was successfully created.'
      redirect_to action: :index
    else
      render :new
    end
  end

  # DELETE /bulk_actions/1
  def destroy
    @bulk_action.destroy
    redirect_to bulk_actions_url, notice: 'Bulk action was deleted.'
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

  # Only accept trusted parameters.
  def bulk_action_params
    params.require(:bulk_action).permit(
      :action_type,
      :description,
      :pids,
      manage_release: %i[tag what who to],
      set_governing_apo: [:new_apo_id],
      manage_catkeys: [:catkeys],
      prepare: %i[significance description],
      create_virtual_objects: [:csv_file],
      import_tags: [:csv_file]
    )
  end
end
