# frozen_string_literal: true

class ApoController < ApplicationController
  before_action :create_obj, except: [
    :new,
    :create,
    :spreadsheet_template
  ]
  after_action :save_and_index, only: [
    :add_roleplayer,
    :add_collection, :delete_collection,
    :update_copyright, :update_creative_commons,
    :update_default_object_rights, :update_desc_metadata,
    :update_title, :update_use
  ]

  before_action :authorize, except: [
    :edit,
    :new,
    :create,
    :spreadsheet_template
  ]

  def edit
    authorize! :create, Dor::AdminPolicyObject
    @form = ApoForm.new(@object)
    render layout: 'blacklight'
  end

  def new
    authorize! :create, Dor::AdminPolicyObject
    @form = ApoForm.new
    render layout: 'blacklight'
  end

  def create
    authorize! :create, Dor::AdminPolicyObject

    @form = ApoForm.new
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
    if @form.default_collection_pid
      notice += " Collection #{@form.default_collection_pid} created."
    end

    redirect_to solr_document_path(@form.model.pid), notice: notice
  end

  def update
    @form = ApoForm.new(@object)
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

  def add_roleplayer
    @object.add_roleplayer(params[:role], params[:roleplayer])
    redirect
  end

  def delete_collection
    @object.remove_default_collection(params[:collection])
    redirect
  end

  def add_collection
    @object.add_default_collection(params[:collection])
    redirect
  end

  def update_title
    @object.mods_title = params[:title]
    redirect
  end

  def update_creative_commons
    @object.creative_commons_license = params[:cc_license]
    @object.creative_commons_license_human = Dor::CreativeCommonsLicenseService.property(params[:cc_license]).label
    redirect
  end

  def update_use
    @object.use_statement = params[:use]
    redirect
  end

  def update_copyright
    @object.copyright_statement = params[:copyright]
    redirect
  end

  def update_default_object_rights
    @object.default_rights = params[:rights]
    redirect
  end

  def update_desc_metadata
    @object.desc_metadata_format = params[:desc_metadata_format]
    redirect
  end

  def spreadsheet_template
    binary_string = Faraday.get(Settings.SPREADSHEET_URL)
    send_data(
      binary_string.body,
      filename: 'spreadsheet_template.xlsx',
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
  end

  private

  def create_obj
    raise 'missing druid' unless params[:id]

    @object = Dor.find params[:id]
  end

  def save_and_index
    @object.save # indexing happens automatically
  end

  def redirect
    respond_to do |format|
      format.any { redirect_to solr_document_path(params[:id]), notice: 'APO updated.' }
    end
  end

  def authorize
    authorize! :manage_item, @object
  end
end
