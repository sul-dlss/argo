# frozen_string_literal: true

class ApoController < ApplicationController
  before_action :create_obj, except: %i[
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
    authorize! :create, Cocina::Models::AdminPolicy
    @form = ApoForm.new(nil, search_service: search_service)

    render layout: 'one_column'
  end

  def create
    authorize! :create, Cocina::Models::AdminPolicy

    change_set = AdminPolicyChangeSet.new
    unless change_set.validate(params[:apo_form].merge(registered_by: current_user.login))
      @form = ApoForm.new(nil, search_service: search_service)
      respond_to do |format|
        format.json { render status: :bad_request, json: { errors: form.errors } }
        format.html { render 'new' }
      end
      return
    end

    change_set.save
    notice = "APO #{change_set.model.externalIdentifier} created."

    # register a collection and make it the default if requested
    notice += " Collection #{change_set.model.administrative.collectionsForRegistration.first} created." if change_set.model.administrative.collectionsForRegistration.present?

    redirect_to solr_document_path(change_set.model.externalIdentifier), notice: notice
  end

  def update
    authorize! :manage_item, @cocina
    change_set = AdminPolicyChangeSet.new(model: @cocina)
    unless change_set.validate(params[:apo_form])
      @form = ApoForm.new(@cocina, search_service: search_service)
      respond_to do |format|
        format.json { render status: :bad_request, json: { errors: @form.errors } }
        format.html { render 'edit' }
      end
      return
    end

    change_set.save
    redirect_to solr_document_path(change_set.model.externalIdentifier)
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
