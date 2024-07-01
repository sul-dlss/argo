# frozen_string_literal: true

class FilesController < ApplicationController
  include ActionController::Live # required for streaming

  before_action :load_resource, except: [:download]

  ##
  # Brings up a modal dialog that lists all locations of the file
  def index
    raise ArgumentError, 'Missing file parameter' if filename.blank?

    @has_been_accessioned = WorkflowService.accessioned?(druid: @cocina_model.externalIdentifier)
    files = Array(@cocina_model.structural&.contains).map { |fs| fs.structural.contains }.flatten
    @file = files.find { |file| file.filename == params[:id] }

    if @has_been_accessioned
      begin
        @last_accessioned_version = last_accessioned_version(params[:item_id])
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
    authorize! :view_content, @cocina_model

    # Set headers on the response before writing to the response stream
    send_file_headers!(
      type: 'application/octet-stream',
      disposition: 'attachment',
      filename: CGI.escape(filename.split('/').last)
    )
    response.headers['Last-Modified'] = Time.now.utc.rfc2822 # HTTP requires GMT date/time

    Preservation::Client.objects.content(
      druid: @cocina_model.externalIdentifier,
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
    message = "Preservation client error getting content of #{filename} for #{@cocina_model.externalIdentifier} (version #{params[:version]}): #{e}"
    logger.error(message)
    Honeybadger.notify(message)
    render status: :internal_server_error, plain: message
  ensure
    response.stream.close
  end

  def download
    if params.key?(:user_version_id)
      @cocina_model = Repository.find_user_version(params[:item_id], params[:user_version_id])
      version = @cocina_model.version
    else
      load_resource
      version = last_accessioned_version(@cocina_model.externalIdentifier)
    end

    authorize! :view_content, @cocina_model

    send_file_headers!(
      type: 'application/zip',
      disposition: 'attachment',
      filename: "#{Druid.new(@cocina_model).without_namespace}.zip"
    )
    response.headers['Last-Modified'] = Time.now.httpdate.to_s
    response.headers['X-Accel-Buffering'] = 'no'

    PresStreamer.stream(druid: @cocina_model.externalIdentifier,
                        version:, filenames: preserved_files(@cocina_model)) do |chunk|
      response.stream.write(chunk)
    end
  ensure
    response.stream.close
  end

  private

  def last_accessioned_version(druid)
    Preservation::Client.objects.current_version(druid)
  end

  def preserved_files(cocina_model)
    resources = Array(cocina_model.structural&.contains)
    resources.flat_map do |resource|
      resource.structural.contains.select do |file|
        file.administrative.sdrPreserve
      end.map(&:filename)
    end
  end

  def filename
    params[:id]
  end

  def load_resource
    @cocina_model = Repository.find(params[:item_id])
  end

  # Zip-tricks based streaming for files from preservation.
  # Based on https://piotrmurach.com/articles/streaming-large-zip-files-in-rails/
  class PresStreamer
    include Enumerable

    def self.stream(druid:, version:, filenames:, &chunks)
      streamer = new(druid:, version:, filenames:)
      streamer.each(&chunks)
    end

    attr_reader :druid, :version, :filenames

    def initialize(druid:, version:, filenames:)
      @druid = druid
      @version = version
      @filenames = filenames
    end

    def each(&)
      writer = ZipTricks::BlockWrite.new(&)

      ZipTricks::Streamer.open(writer) do |zip|
        filenames.each do |filename|
          Rails.logger.info("Adding #{filename} to zip")
          zip.write_deflated_file(filename) do |file_writer|
            Preservation::Client.objects.content(druid:,
                                                 filepath: filename,
                                                 version:,
                                                 on_data: proc { |data, _count|
                                                            file_writer.write data
                                                          })
          rescue StandardError => e
            file_writer.close
            message = "Could not zip #{filename} (#{druid}) for download: #{e}"
            Rails.logger.error(message)
            Honeybadger.notify(message)
            next
          end
        end
      end
    end
  end
end
