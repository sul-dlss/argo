# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def show
    @apo_list = AdminPolicyOptions.for(current_user)
    @registration_form = RegistrationForm.new(nil)
    prepopulate

    # Handle "Back to form" functionality
    @registration_form.deserialize(create_params) if params.key?(:registration)
  end

  def create
    if params[:registration][:csv_file]
      csv_create
    else
      form_create
    end
  end

  def tracksheet
    druids = Array(params[:druid]).map { |druid| Druid.new(druid).without_namespace }
    name = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = TrackSheet.new(druids).generate_tracking_pdf
    render plain: pdf.render, content_type: :pdf
  end

  def autocomplete
    facet_field = 'project_tag_ssim'
    response = SearchService.query(
      '*:*',
      rows: 0,
      'facet.field': facet_field,
      'facet.prefix': params[:term].titlecase,
      'facet.mincount': 1,
      'facet.limit': 15,
      'json.nl': 'map'
    )
    result = response['facet_counts']['facet_fields'][facet_field].keys.sort
    render json: result
  end

  # Allow the front end to check if a source Id already exists
  def source_id
    raise 'Malformed input' unless Regexp.new(Settings.source_id_regex).match?(params[:source_id])

    begin
      Dor::Services::Client.objects.find(source_id: params[:source_id])
      resp = true
    rescue Dor::Services::Client::NotFoundResponse
      resp = false
    end

    render json: resp.to_json, layout: false
  end

  # Allow the front end to check if a catalog record ID exists
  def catalog_record_id
    resp = begin
      FolioClient.fetch_instance_info(hrid: params[:catalog_record_id])
      true
    rescue FolioClient::ResourceNotFound, FolioClient::MultipleResourcesFound
      false
    rescue FolioClient::Error => e
      # In production, this will prevent registration attempt when ILS (Folio) is not available.
      # In other environments, where Folio is never available, it will allow registration.
      return render plain: e.message, status: :bad_gateway if Rails.env.production?

      true
    end
    render json: resp.to_json, layout: false
  end

  # Server-side check for MARC record availability on multiple registered items (lazy-loaded in a Turbo Frame)
  def marc_warnings
    @warnings = []

    Array(params[:items]).each do |item|
      druid = item[:druid]
      catalog_record_id = item[:catalog_record_id]
      next if catalog_record_id.blank?

      has_marc = begin
        FolioClient.fetch_marc_hash(instance_hrid: catalog_record_id)
        true
      rescue FolioClient::ResourceNotFound
        false
      rescue FolioClient::Error => e
        # In production, this will prevent false negatives when ILS (Folio) is not available.
        # In other environments, where Folio is never available, it will assume MARC exists.
        Rails.logger.warn("FolioClient error in marc_warnings for #{catalog_record_id}: #{e.message}")
        true
      end

      @warnings << { druid: druid, catalog_record_id: catalog_record_id } unless has_marc
    end

    render layout: false
  end

  def spreadsheet
    respond_to do |format|
      format.csv do
        csv_template = CSV.generate do |csv|
          csv << ['barcode', CatalogRecordId.csv_header, 'source_id', 'title']
        end
        send_data csv_template, filename: 'registration.csv'
      end
    end
  end

  private

  def apo_id
    @apo_id ||= Druid.new(params.require(:apo_id)).with_namespace
  end

  def render_failure(error)
    return render plain: error.message, status: :conflict if error.errors.first&.fetch('status') == '422'

    render plain: error.message, status: :bad_request
  end

  def form_create
    @registration_form = RegistrationForm.new(nil)
    if @registration_form.validate(create_params) && @registration_form.save
      @folio_items_to_check = @registration_form.created.filter_map do |dro|
        hrid = dro.identification.catalogLinks.first&.catalogRecordId
        { druid: Druid.new(dro).without_namespace, catalog_record_id: hrid } if hrid.present?
      end
      render 'create_status'
    else
      prepopulate
      render :show, status: :bad_request
    end
  end

  def csv_create
    @registration_form = CsvRegistrationForm.new(nil)
    if @registration_form.validate(create_params) && @registration_form.save
      redirect_to bulk_actions_path, status: :see_other, notice: 'Register druids job was successfully created.'
    else
      prepopulate(user_values: create_params) # set form values based on what user already entered
      render :show, status: :bad_request
    end
  end

  def create_params
    params.require(:registration).to_unsafe_h.merge(current_user:)
  end

  def prepopulate(user_values: {})
    @apo_list = AdminPolicyOptions.for(current_user)
    @registration_form.prepopulate!(user_values)
    @registration_form.admin_policy ||= @apo_list.first.last
  end
end
