# frozen_string_literal: true

class Dor::ObjectsController < ApplicationController
  before_action :munge_parameters

  def create
    form = RegistrationForm.new(params).tap { |f| f.current_user = current_user }
    request_model = form.cocina_model # might raise Cocina::Models::ValidationError
    result = RegistrationService.register(model: request_model, workflow: params[:workflow_id], tags: form.tags)
    result.either(
      ->(model) { render json: { druid: model.externalIdentifier }, status: :created, location: solr_document_url(model.externalIdentifier) },
      ->(error) { render_failure(error) }
    )
  rescue Cocina::Models::ValidationError => e
    render plain: e.message, status: :bad_request
  end

  private

  def render_failure(error)
    return render plain: error.message, status: :conflict if error.errors.first&.fetch('status') == '422'

    render plain: error.message, status: :bad_request
  end

  def munge_parameters
    case request.media_type
    when 'application/xml', 'text/xml'
      merge_params(Hash.from_xml(request.body.read))
    when 'application/json', 'text/json'
      merge_params(JSON.parse(request.body.read))
    end
  end

  def merge_params(hash)
    # convert camelCase parameter names to under_score, and string keys to symbols
    # e.g., 'objectType' to :object_type
    hash.each_pair do |k, v|
      key = k.underscore
      params[key.to_sym] = v
    end
  end
end
