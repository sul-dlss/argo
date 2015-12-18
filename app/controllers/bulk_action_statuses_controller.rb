class BulkActionStatusesController < ApplicationController
  before_action :set_bulk_action_status, only: [:show, :edit, :update, :destroy]

  # GET /bulk_action_statuses
  def index
    @bulk_action_statuses = BulkActionStatus.all
  end

  # GET /bulk_action_statuses/1
  def show
  end

  # GET /bulk_action_statuses/new
  def new
    @bulk_action_status = BulkActionStatus.new
  end

  # GET /bulk_action_statuses/1/edit
  def edit
  end

  # POST /bulk_action_statuses
  def create
    @bulk_action_status = BulkActionStatus.new(bulk_action_status_params)

    if @bulk_action_status.save
      redirect_to @bulk_action_status, notice: 'Bulk action status was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /bulk_action_statuses/1
  def update
    if @bulk_action_status.update(bulk_action_status_params)
      redirect_to @bulk_action_status, notice: 'Bulk action status was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /bulk_action_statuses/1
  def destroy
    @bulk_action_status.destroy
    redirect_to bulk_action_statuses_url, notice: 'Bulk action status was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bulk_action_status
      @bulk_action_status = BulkActionStatus.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def bulk_action_status_params
      params.require(:bulk_action_status).permit(:success, :completed, :started)
    end
end
