# frozen_string_literal: true

class BulkActionsController < ApplicationController
  include Blacklight::SearchContext

  before_action :set_bulk_action, only: %i[destroy file]

  # GET /bulk_actions
  def index
    @bulk_actions = BulkAction.where(user: current_user).order('created_at DESC')
  end

  # GET /bulk_actions/new
  def new
    @form = BulkActionForm.new(BulkAction.new, groups: current_user.groups)
  end

  # POST /bulk_actions
  def create
    # Since the groups aren't persisted, we need to pass them here.
    @form = BulkActionForm.new(BulkAction.new(user: current_user), groups: current_user.groups)
    if @form.validate(bulk_action_params) && @form.save
      flash[:notice] = 'Bulk action was successfully created.'
      redirect_to action: :index
    else
      render :new, status: :unprocessable_entity
    end
  end

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

  # Only accept trusted parameters.
  def bulk_action_params
    params.require(:bulk_action).permit(
      :action_type,
      :description,
      :pids,
      add_workflow: %i[workflow],
      manage_release: %i[tag what who to],
      set_governing_apo: [:new_apo_id],
      set_catkeys_and_barcodes: %i[
        catkeys use_catkeys_option
        barcodes use_barcodes_option
      ],
      set_catkeys_and_barcodes_csv: [:csv_file],
      set_source_ids_csv: [:csv_file],
      prepare: %i[significance description],
      create_virtual_objects: [:csv_file],
      import_tags: [:csv_file],
      register_druids: [:csv_file],
      set_license_and_rights_statements: %i[
        copyright_statement copyright_statement_option
        license license_option
        use_statement use_statement_option
      ],
      manage_embargo: [:csv_file],
      set_content_type: %i[
        current_resource_type
        new_content_type new_resource_type
      ],
      set_collection: [:new_collection_id],
      set_rights: [:rights]
    )
  end
end
