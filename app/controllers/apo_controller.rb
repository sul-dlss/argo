# frozen_string_literal: true

class ApoController < ApplicationController
  before_action :create_obj, except: %i[
    new
    create
    spreadsheet_template
  ]

  def edit
    authorize! :create, Cocina::Models::AdminPolicy
    object = Dor.find params[:id]

    @form = ApoForm.new(object, search_service: search_service)
    render layout: 'one_column'
  end

  def new
    authorize! :create, Cocina::Models::AdminPolicy
    @form = ApoForm.new(Dor::AdminPolicyObject.new, search_service: search_service)
    render layout: 'one_column'
  end

  def create
    authorize! :create, Cocina::Models::AdminPolicy

    @form = ApoForm.new(Dor::AdminPolicyObject.new, search_service: search_service)
    unless @form.validate(params.merge(tag: "Registered By : #{current_user.login}"))
      respond_to do |format|
        format.json { render status: :bad_request, json: { errors: form.errors } }
        format.html { render 'new' }
      end
      return
    end

    @form.save
    notice = "APO #{@form.model.pid} created."

    # register a collection and make it the default if requested
    notice += " Collection #{@form.default_collection_pid} created." if @form.default_collection_pid

    redirect_to solr_document_path(@form.model.pid), notice: notice
  end

  def update
    authorize! :manage_item, @cocina
    object = Dor.find params[:id]

    @form = ApoForm.new(object, search_service: search_service)
    unless @form.validate(params)
      respond_to do |format|
        format.json { render status: :bad_request, json: { errors: @form.errors } }
        format.html { render 'edit' }
      end
      return
    end

    @form.save
    redirect_to solr_document_path(@form.model.pid)
  end

  def delete_collection
    authorize! :manage_item, @cocina
    collection_ids = @cocina.administrative.collectionsForRegistration - [params[:collection]]
    updated_administrative = @cocina.administrative.new(collectionsForRegistration: collection_ids)
    updated = @cocina.new(administrative: updated_administrative)
    Dor::Services::Client.object(@cocina.externalIdentifier).update(params: updated)

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

  private

  def search_service
    @search_service ||= Blacklight::SearchService.new(config: CatalogController.blacklight_config,
                                                      current_user: current_user)
  end

  def create_obj
    raise 'missing druid' unless params[:id]

    @cocina = maybe_load_cocina(params[:id])
  end
end
