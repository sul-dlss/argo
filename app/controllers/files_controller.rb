# frozen_string_literal: true

class FilesController < ApplicationController
  before_action :load_resource, only: [:show, :preserved]

  ##
  # Brings up a modal dialog that lists all locations of the file
  def index
    raise ArgumentError, 'Missing file parameter' if filename.blank?

    object_client = Dor::Services::Client.object(params[:item_id])
    @available_in_workspace = object_client.files.list.include?(filename)
    @has_been_accessioned = WorkflowClientFactory.build.lifecycle('dor', params[:item_id], 'accessioned')
    files = object_client.find.structural.contains.map { |fs| fs.structural.contains }.flatten
    @file = files.find { |file| file.externalIdentifier == "#{params[:item_id]}/#{params[:id]}" }

    if @has_been_accessioned
      begin
        @last_accessioned_version = Preservation::Client.objects.current_version(params[:item_id])
      rescue Preservation::Client::NotFoundError
        return render status: :unprocessable_entity, plain: "Preservation has not yet received #{params[:item_id]}"
      rescue Preservation::Client::Error => e
        message = "Preservation client error getting current version of #{params[:item_id]}: #{e}"
        logger.error(message)
        Honeybadger.notify(message)
        return render status: :internal_server_error, plain: message
      end
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def show
    authorize! :view_content, @object
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = 'attachment; filename=' + filename
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = Dor::Services::Client.object(params[:item_id]).files.retrieve(filename: filename)
  end

  def preserved
    authorize! :view_content, @object
    file_content = Preservation::Client.objects.content(druid: @object.pid, filepath: filename, version: params[:version])
    response.headers['Content-Type'] = 'application/octet-stream'
    response.headers['Content-Disposition'] = "attachment; filename=#{CGI.escape(filename)}"
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time
    self.response_body = file_content
  rescue Preservation::Client::NotFoundError => e
    render status: :not_found, plain: "Preserved file not found: #{e}"
  rescue Preservation::Client::Error => e
    message = "Preservation client error getting content of #{filename} for #{@object.pid} (version #{params[:version]}): #{e}"
    logger.error(message)
    Honeybadger.notify(message)
    render status: :internal_server_error, plain: message
  end

  private

  def filename
    params[:id]
  end

  def load_resource
    @object = Dor.find params[:item_id]
  end
end
