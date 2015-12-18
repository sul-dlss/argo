class BulkActionMessagesController < ApplicationController
  before_action :set_bulk_action_message, only: [:show, :edit, :update, :destroy]

  # GET /bulk_action_messages
  def index
    @bulk_action_messages = BulkActionMessage.all
  end

  # GET /bulk_action_messages/1
  def show
  end

  # GET /bulk_action_messages/new
  def new
    @bulk_action_message = BulkActionMessage.new
  end

  # GET /bulk_action_messages/1/edit
  def edit
  end

  # POST /bulk_action_messages
  def create
    @bulk_action_message = BulkActionMessage.new(bulk_action_message_params)

    if @bulk_action_message.save
      redirect_to @bulk_action_message, notice: 'Bulk action message was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /bulk_action_messages/1
  def update
    if @bulk_action_message.update(bulk_action_message_params)
      redirect_to @bulk_action_message, notice: 'Bulk action message was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /bulk_action_messages/1
  def destroy
    @bulk_action_message.destroy
    redirect_to bulk_action_messages_url, notice: 'Bulk action message was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bulk_action_message
      @bulk_action_message = BulkActionMessage.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def bulk_action_message_params
      params.require(:bulk_action_message).permit(:message, :druid)
    end
end
