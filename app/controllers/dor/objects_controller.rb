# frozen_string_literal: true

class Dor::ObjectsController < ApplicationController
  include ApplicationHelper # for fedora_base
  before_action :munge_parameters

  def create
    form = RegistrationForm.new(params)
    begin
      response = Dor::Services::Client.objects.register(params: form.cocina_model)
    rescue Cocina::Models::ValidationError => e
      return render plain: e.message, status: :bad_request
    rescue Dor::Services::Client::UnexpectedResponse => e
      return render plain: e.message, status: :conflict if e.message.start_with?('Conflict')

      return render plain: e.message, status: :bad_request
    end

    pid = response.externalIdentifier

    WorkflowClientFactory.build.create_workflow_by_name(pid, params[:workflow_id], version: '1')

    Dor::Services::Client.object(pid).administrative_tags.create(tags: form.administrative_tags)

    render json: { pid: pid }, status: :created, location: object_location(pid)
  end

  private

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
