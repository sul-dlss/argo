# frozen_string_literal: true

class FilesController < ApplicationController
  before_action :load_resource

  ##
  # Brings up a modal dialog that lists all locations of the file
  def index
    raise ArgumentError, 'Missing file parameter' if params[:id].blank?

    @available_in_workspace_error = nil
    @available_in_workspace = @object.list_files.include?(params[:id])

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  rescue Net::SSH::Exception => e
    @available_in_workspace_error = "#{e.class}: #{e}"
  end

  def show
    authorize! :view_content, @object
    data = @object.get_file(params[:id])
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id]
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = data
  end

  def preserved
    authorize! :view_content, @object
    file_content = @object.get_preserved_file params[:id], params[:version].to_i
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = "attachment; filename=#{params[:id]}"
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = file_content
  end

  private

  def load_resource
    @object = Dor.find params[:item_id]
  end
end
