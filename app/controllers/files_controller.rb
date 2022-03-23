# frozen_string_literal: true

class FilesController < ApplicationController
  include ActionController::Live # required for streaming
  include ZipTricks::RailsStreaming

  before_action :load_resource

  ##
  # Brings up a modal dialog that lists all locations of the file
  def index
    raise ArgumentError, 'Missing file parameter' if filename.blank?

    @has_been_accessioned = WorkflowClientFactory.build.lifecycle(druid: params[:item_id], milestone_name: 'accessioned')
    files = @item.file_sets.map(&:files).flatten
    @file = files.find { |file| file.filename == params[:id] }

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

  def preserved
    authorize! :view_content, @item

    # Set headers on the response before writing to the response stream
    send_file_headers!(
      type: 'application/octet-stream',
      disposition: 'attachment',
      filename: CGI.escape(filename)
    )
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time

    Preservation::Client.objects.content(
      druid: @item.id,
      filepath: filename,
      version: params[:version],
      on_data: proc { |data, _count| response.stream.write data }
    )
  rescue Preservation::Client::NotFoundError => e
    # Undo the header setting above for the streaming response. Not relevant here.
    response.headers.delete('Last-Modified')
    response.headers.delete('Content-Disposition')

    render status: :not_found, plain: "Preserved file not found: #{e}"
  rescue Preservation::Client::Error => e
    message = "Preservation client error getting content of #{filename} for #{@item.id} (version #{params[:version]}): #{e}"
    logger.error(message)
    Honeybadger.notify(message)
    render status: :internal_server_error, plain: message
  ensure
    response.stream.close
  end

  def download
    authorize! :view_content, @item

    response.headers['Content-Disposition'] = "attachment; filename=#{Druid.new(@item.id).without_namespace}.zip"
    zip_tricks_stream do |zip|
      preserved_files(@item).each do |filename|
        zip.write_deflated_file(filename) do |sink|
          Preservation::Client.objects.content(druid: @item.id,
                                               filepath: filename,
                                               version: @item.version,
                                               on_data: proc { |data, _count| sink.write data })
        rescue StandardError => e
          sink.close
          message = "Could not zip #{filename} (#{@item.id}) for download: #{e}"
          logger.error(message)
          Honeybadger.notify(message)
          render status: :internal_server_error, plain: message
        end
      end
    end
  end

  private

  def preserved_files(item)
    item.file_sets.flat_map do |file_set|
      file_set.files.select(&:preserve).map(&:filename)
    end
  end

  def filename
    params[:id]
  end

  def load_resource
    @item = Repository.find(params[:item_id])
  end
end
