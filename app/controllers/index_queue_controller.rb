class IndexQueueController < ApplicationController
  ##
  # Client side access to the index queue depth
  def depth
    render json: IndexQueue.new.depth.to_json, layout: false
  end
end
