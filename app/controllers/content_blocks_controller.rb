# frozen_string_literal: true

class ContentBlocksController < ApplicationController
  before_action :set_content_block, only: %i[create update destroy]
  authorize_resource

  # GET /content_blocks
  def index
    @unexpired_blocks = ContentBlock.unexpired
    @expired_blocks = ContentBlock.expired
  end

  # POST /content_blocks
  def create
    @content_block.save!
    redirect_to content_blocks_path
  end

  # PATCH/PUT /content_blocks/1
  def update
    @content_block.save!
    redirect_to content_blocks_path
  end

  # DELETE /content_blocks/1
  def destroy
    @content_block.destroy
    redirect_to content_blocks_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_content_block
    @content_block = params[:id] ? ContentBlock.find(params[:id]) : ContentBlock.new
    return unless params[:content_block]

    start_at = params[:content_block][:start_at].in_time_zone('America/Los_Angeles')
    end_at = params[:content_block][:end_at].in_time_zone('America/Los_Angeles').end_of_day
    @content_block.attributes = { end_at: end_at, start_at: start_at, ordinal: params[:content_block][:ordinal], value: params[:content_block][:value] }
  end
end
