# frozen_string_literal: true

class Dor::ObjectsController < ApplicationController
  include ApplicationHelper # for fedora_base
  before_action :munge_parameters

  def create
    form = RegistrationForm.new(params)
    request_model = form.cocina_model # might raise Cocina::Models::ValidationError
    result = RegistrationService.register(model: request_model, workflow: params[:workflow_id], tags: form.administrative_tags)

    result.either(
      ->(model) { render json: { pid: model.externalIdentifier }, status: :created, location: object_location(model.externalIdentifier) },
      ->(message) { render_failure(message) }
    )
  rescue Cocina::Models::ValidationError => e
    render plain: e.message, status: :bad_request
  end

  private

  def render_failure(message)
    return render plain: message, status: :conflict if message.start_with?('Conflict')

    render plain: message, status: :bad_request
  end

  def munge_parameters
    case request.content_type
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

  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end
end
