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
    raw_content = @object_client.metadata.datastream(params[:id])
    @content = Nokogiri::XML(raw_content, &:noblanks).to_s

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
    cocina = Repository.find(params[:item_id])
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
    Argo::Indexer.reindex_druid_remotely(druid)
  end

  def show_aspect
    druid = Druid.new(params[:item_id]).with_namespace
    @response, @document = search_service.fetch druid # this does the authorization
    @item = Repository.find(druid)
    @object_client = Dor::Services::Client.object(druid)
  end
end
