# frozen_string_literal: true

class RegistrationsController < ApplicationController
  def show
    @apo_list = AdminPolicyOptions.for(current_user)
    @registration_form = RegistrationForm.new(nil)
    @registration_form.prepopulate!
  end

  def create
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

  private

  def apo_id
    @apo_id ||= Druid.new(params.require(:apo_id)).with_namespace
  end

  def render_failure(error)
    return render plain: error.message, status: :conflict if error.errors.first&.fetch('status') == '422'

    render plain: error.message, status: :bad_request
  end
end
