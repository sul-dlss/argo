# frozen_string_literal: true

class DatastreamsController < ApplicationController
  include Blacklight::Catalog
  copy_blacklight_config_from CatalogController

  before_action :show_aspect, only: %i[dc show edit]

  def dc
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def edit
    @ds = @obj.datastreams[params[:id]]
    render layout: !request.xhr?
  end

  def show
    if params[:dsid] == 'full_dc'
      @content = Nokogiri::XML(Dor::Services::Client.object(@obj.pid).metadata.dublin_core).prettify
    else
      @ds = @obj.datastreams[params[:id]]

      @content = if @ds.respond_to? :ng_xml
                   Nokogiri::XML(@ds.ng_xml.to_s, &:noblanks).to_s
                 else
                   Nokogiri::XML(@ds.content, &:noblanks).to_s
                 end
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
    cocina = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, cocina

    raise ArgumentError, 'Missing content' if params[:content].blank?

    begin
      Nokogiri::XML(params[:content], &:strict)
      @object = Dor.find params[:item_id]
      @object.datastreams[params[:id]].content = params[:content] # set the XML to be verbatim as posted
      @object.save
      Argo::Indexer.reindex_pid_remotely(@object.pid)
      msg = 'Datastream was successfully updated'
    rescue Nokogiri::XML::SyntaxError
      # if the content is not well-formed xml, inform the user rather than raising an exception
      error_msg = 'The datastream could not be saved due to malformed XML.'
    end

    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:item_id]), notice: msg, flash: { error: error_msg } }
    end
  end

  private

  def show_aspect
    pid = params[:item_id].include?('druid') ? params[:item_id] : "druid:#{params[:item_id]}"
    @obj = Dor.find(pid)
    @response, @document = search_service.fetch pid # this does the authorization
  end
end
