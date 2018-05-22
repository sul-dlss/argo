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
    :update_title, :update_use,
    :delete_role,
    :register_collection
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
    @cur_default_workflow = @object.administrativeMetadata.ng_xml.xpath('//registration/workflow/@id').to_s
    render layout: 'blacklight'
  end

  def new
    authorize! :create, Dor::AdminPolicyObject
    @form = ApoForm.new
    render layout: 'blacklight'
  end

  def create
    authorize! :create, Dor::AdminPolicyObject

    form = ApoForm.new
    unless form.validate(params.merge(tag: "Registered By : #{current_user.login}"))
      render status: :bad_request, json: { errors: form.errors }
      return
    end

    form.save
    notice = "APO #{form.model.pid} created."

    # register a collection and make it the default if requested
    if form.default_collection_pid
      notice += " Collection #{form.default_collection_pid} created."
    end

    redirect_to solr_document_path(form.model.pid), notice: notice
  end

  # wrapper around call to update_index for various objects (APO, collection, item)
  # provides easily-stubbed method for testing (instead of all object types)
  def update_index(obj)
    obj.update_index
  end

  def update
    form = ApoForm.new(@object)
    unless form.validate(params)
      render status: :bad_request, json: { errors: form.errors }
      return
    end
    form.save

    redirect_to solr_document_path(form.model)
  end

  # This handles both the show and save of the form
  def register_collection
    return unless params[:collection_title].present? || params[:collection_catkey].present?
    form = CollectionForm.new
    return unless form.validate(params.merge(apo_pid: params[:id]))
    form.save
    collection_pid = form.model.id
    @object.add_default_collection collection_pid
    redirect_to solr_document_path(params[:id]), notice: "Created collection #{collection_pid}"
  end

  def add_roleplayer
    @object.add_roleplayer(params[:role], params[:roleplayer])
    redirect
  end

  def delete_role
    @object.delete_role(params[:role], params[:roleplayer])
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
    @object.creative_commons_license_human = Dor::Editable::CREATIVE_COMMONS_USE_LICENSES[params[:cc_license]][:human_readable]
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
    pids = @object.default_collections || []
    @collections = pids.map { |pid| Dor.find(pid) }
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
