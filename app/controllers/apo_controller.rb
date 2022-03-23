# frozen_string_literal: true

class ApoController < ApplicationController
  include Blacklight::FacetsHelperBehavior # for facet_configuration_for_field

  before_action :load_resource, except: %i[
    new
    create
    spreadsheet_template
  ]

  def edit
    authorize! :manage_item, @cocina
    @form = ApoForm.new(@cocina, search_service: search_service)

    render layout: 'one_column'
  end

  def new
    authorize! :create, AdminPolicy
    @form = ApoForm.new(nil, search_service: search_service)

    render layout: 'one_column'
  end

  def create
    authorize! :create, AdminPolicy
    @form = ApoForm.new(nil, search_service: search_service)
    unless @form.validate(params.require(:apo).to_unsafe_h.merge(registered_by: current_user.login))
      respond_to do |format|
        format.json { render status: :bad_request, json: { errors: @form.errors } }
        format.html { render 'new', status: :unprocessable_entity }
      end
      return
    end

    @form.save
    notice = "APO #{@form.model.externalIdentifier} created."

    # register a collection and make it the default if requested
    notice += " Collection #{@form.model.administrative.collectionsForRegistration.first} created." if @form.model.administrative.collectionsForRegistration.present?

    redirect_to solr_document_path(@form.model.externalIdentifier), notice: notice
  end

  def update
    authorize! :manage_item, @cocina
    @form = ApoForm.new(@cocina, search_service: search_service)
    unless @form.validate(params.require(:apo).to_unsafe_h)
      respond_to do |format|
        format.json { render status: :unprocessable_entity, json: { errors: @form.errors } }
        format.html { render 'edit', status: :unprocessable_entity }
      end
      return
    end

    @form.save
    redirect_to solr_document_path(@form.model.externalIdentifier)
  end

  def delete_collection
    authorize! :manage_item, @cocina
    collection_ids = @cocina.administrative.collectionsForRegistration - [params[:collection]]
    updated_administrative = @cocina.administrative.new(collectionsForRegistration: collection_ids)
    updated = @cocina.new(administrative: updated_administrative)
    Repository.store(updated)

    redirect_to solr_document_path(params[:id]), notice: 'APO updated.'
  end

  def spreadsheet_template
    binary_string = Faraday.get(Settings.spreadsheet_url)
    send_data(
      binary_string.body,
      filename: 'spreadsheet_template.xlsx',
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  # Displays the turbo-frame that has a link to collections governed by this APO
  def count_collections
    query = "_query_:\"{!raw f=#{ApoConcern::FIELD_APO_ID}}info:fedora/#{params[:id]}\" AND " \
            "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}collection\""
    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })

    path_for_search = link_to_members_with_type('collection')

    render partial: 'count_collections', locals: { count: result.dig('response', 'numFound'), path_for_search: path_for_search }
  end

  # Displays the turbo-frame that has a link to items governed by this APO
  def count_items
    query = "_query_:\"{!raw f=#{ApoConcern::FIELD_APO_ID}}info:fedora/#{params[:id]}\" AND " \
            "_query_:\"{!raw f=#{SolrDocument::FIELD_OBJECT_TYPE}}item\""
    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })

    path_for_search = link_to_members_with_type('item')

    render partial: 'count_items', locals: { count: result.dig('response', 'numFound'), path_for_search: path_for_search }
  end

  def search_action_path(*args)
    search_catalog_path(*args)
  end

  private

  def search_service
    @search_service ||= Blacklight::SearchService.new(config: CatalogController.blacklight_config,
                                                      current_user: current_user)
  end

  def link_to_members_with_type(type)
    facet_config = facet_configuration_for_field(ApoConcern::FIELD_APO_ID)
    search_state = Blacklight::SearchState.new({ f: { SolrDocument::FIELD_OBJECT_TYPE => [type] } }, blacklight_config)
    Blacklight::FacetItemPresenter.new("info:fedora/#{params[:id]}",
                                       facet_config,
                                       self,
                                       ApoConcern::FIELD_APO_ID, search_state).href
  end

  def solr_conn
    @solr_conn ||= blacklight_config.repository_class.new(blacklight_config).connection
  end

  def load_resource
    @cocina = Repository.find(params[:id])
  end
end
