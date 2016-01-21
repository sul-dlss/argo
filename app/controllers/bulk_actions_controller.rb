class BulkActionsController < ApplicationController
#  before_action :set_bulk_action, only: [:show, :edit, :update, :destroy]

  # GET /bulk_actions
  def index
    @bulk_actions = BulkAction.all
  end

  # GET /bulk_actions/1
  def show
  end

  # GET /bulk_actions/new
  def new
    @bulk_action = BulkAction.new
  end

  # GET /bulk_actions/1/edit
  def edit
  end

  # POST /bulk_actions
  def create
#    @bulk_action = BulkAction.new(bulk_action_params)
    @bulk_action = BulkAction.new(druid_count_success: 0, druid_count_fail: 0, druid_count_total: 5)
#    binding.pry
    @bulk_action.save
    puts "tommy"

    if @bulk_action.save
#      binding.pry
      @druid_list = ['druid:hj185vb7593', 'druid:kv840rx2720', 'druid:pv820dk6668', 'druid:qq613vj0238', 'druid:rn653dy9317', 'druid:xb482bw3979']
      DescmetadataDownloadJob.perform_later(@druid_list, @bulk_action.id, '/tmp/')
      redirect_to @bulk_action, notice: 'Bulk action was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /bulk_actions/1
  def update
    if @bulk_action.update(bulk_action_params)
      redirect_to @bulk_action, notice: 'Bulk action was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /bulk_actions/1
  def destroy
    @bulk_action.destroy
    redirect_to bulk_actions_url, notice: 'Bulk action was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
#    def set_bulk_action
#      @bulk_action = BulkAction.find(params[:id])
#    end

    # Only allow a trusted parameter "white list" through.
#    def bulk_action_params
#      params.require(:bulk_action).permit(:action_type, :status, :log_name, :description, :druid_count_total)
#    end
end
