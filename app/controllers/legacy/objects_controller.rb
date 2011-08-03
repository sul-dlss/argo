class Legacy::ObjectsController < ApplicationController

  def index
    conditions = params.reject { |k,v| not Legacy::Object.column_names.include?(k.to_s) }
    @objects = Legacy::Object.where(conditions)
    respond_to do |format|
      format.text { render :text => @objects.collect { |r| "druid:#{r.druid}" }.join("\n") }
      format.any(:json, :xml) { render request.format.to_sym => @objects }
    end
  end

end
