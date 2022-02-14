# frozen_string_literal: true

class DatastreamsController < ApplicationController
  include Blacklight::Catalog
  copy_blacklight_config_from CatalogController

  before_action :show_aspect, only: %i[show edit]

  def edit
    @content = @object_client.metadata.datastream(params[:id])
    render layout: !request.xhr?
  end

  def show
    if params[:id] == 'full_dc'
      @content = PrettyXml.print(@object_client.metadata.dublin_core)
    else
      raw_content = @object_client.metadata.datastream(params[:id])
      @content = Nokogiri::XML(raw_content, &:noblanks).to_s
    end

    raise ActionController::RoutingError, 'Not Found' if @content.nil?

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  ##
  # @option params [String] `:content` the XML with which to replace the datastream
  # @option params [String] `:id` the identifier for the datastream, e.g., `identityMetadata`
  # @option params [String] `:item_id` the druid to modify
  def update
    cocina = maybe_load_cocina(params[:item_id])
    authorize! :manage_item, cocina

    raise ArgumentError, 'Missing content' if params[:content].blank?

    begin
      Nokogiri::XML(params[:content], &:strict)
      store_xml(druid: params[:item_id], datastream: params[:id], content: params[:content])
      msg = 'Datastream was successfully updated'
    rescue Nokogiri::XML::SyntaxError
      # if the content is not well-formed xml, inform the user rather than raising an exception
      error_msg = 'The datastream could not be saved due to malformed XML.'
    rescue Dor::Services::Client::UnexpectedResponse => e
      error_msg = e.message
    end

    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:item_id]), notice: msg, flash: { error: error_msg&.truncate(254) } }
    end
  end

  def self.endpoint_for_datastream(datastream)
    case datastream
    when 'RELS-EXT'
      'relationships'
    when 'descMetadata'
      'descriptive'
    else
      datastream.delete_suffix('Metadata')
    end
  end

  private

  def store_xml(druid:, datastream:, content:)
    endpoint = self.class.endpoint_for_datastream datastream

    object_client = Dor::Services::Client.object(druid)
    object_client.metadata.legacy_update(
      endpoint.to_sym => {
        updated: Time.zone.now,
        content: content
      }
    )
    Argo::Indexer.reindex_pid_remotely(druid)
  end

  def show_aspect
    pid = params[:item_id].include?('druid') ? params[:item_id] : "druid:#{params[:item_id]}"
    @response, @document = search_service.fetch pid # this does the authorization
    @cocina = maybe_load_cocina(pid)
    @object_client = Dor::Services::Client.object(pid)
  end
end
