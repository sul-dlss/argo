# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def show
    @apo_list = AdminPolicyOptions.for(current_user)
    @registration_form = RegistrationForm.new(nil)
    @registration_form.prepopulate!
  end

  def create
    if params[:registration][:csv_file]
      csv_create
    else
      form_create
    end
  end

  def tracksheet
    druids   = Array(params[:druid])
    name     = params[:name] || 'tracksheet'
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
    raise 'Malformed input' unless /\A[\w:]+\z/.match?(params[:source_id])

    query = "_query_:\"{!raw f=#{SolrDocument::FIELD_SOURCE_ID}}#{params[:source_id]}\""
    solr_conn = blacklight_config.repository_class.new(blacklight_config).connection
    result = solr_conn.get('select', params: { q: query, qt: 'standard', rows: 0 })
    resp = result.dig('response', 'numFound').to_i.positive?

    render json: resp.to_json, layout: false
  end

  def spreadsheet
    respond_to do |format|
      format.csv do
        csv_template = CSV.generate do |csv|
          csv << %w[source_id catkey barcode label]
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
    create_params = params.require(:registration).to_unsafe_h.merge(current_user:)
    if @registration_form.validate(create_params) && @registration_form.save
      render 'create_status'
    else
      @apo_list = AdminPolicyOptions.for(current_user)
      @registration_form.prepopulate!
      render :show, status: :bad_request
    end
  end

  def csv_create
    @registration_form = CsvRegistrationForm.new(nil)
    if @registration_form.validate(create_params) && @registration_form.save
      # # strip the CSRF token, and the parameters that happened to be in the bulk job creation form
      # # this can be removed when this is resolved: https://github.com/projectblacklight/blacklight/issues/2683
      # search_state_subset = search_state.to_h.except(:authenticity_token, :druids, :druids_only, :description)
      # path_params = Blacklight::Parameters.sanitize(search_state_subset)
      # redirect_to bulk_actions_path(path_params), status: :see_other, notice: success_message
      redirect_to bulk_actions_path, status: :see_other, notice: 'Register druids job was successfully created.'
    else
      @apo_list = AdminPolicyOptions.for(current_user)
      @registration_form.prepopulate!
      render :show, status: :bad_request
    end
  end

  def create_params
    params.require(:registration).to_unsafe_h.merge(current_user:)
  end
end
