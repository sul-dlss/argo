# frozen_string_literal: true

class Dor::ObjectsController < ApplicationController
  include ApplicationHelper # for fedora_base
  before_action :munge_parameters

  def create
    if params[:collection] && params[:collection].length == 0
      params.delete :collection
    end

    begin
      response = Dor::Services::Client.objects.register(params: cocina_model)
    rescue Cocina::Models::ValidationError => e
      return render plain: e.message, status: :bad_request
    rescue Dor::Services::Client::UnexpectedResponse => e
      return render plain: e.message, status: :conflict if e.message.start_with?('Conflict')

      return render plain: e.message, status: :bad_request
    end

    pid = response.externalIdentifier

    WorkflowClientFactory.build.create_workflow_by_name(pid, params[:workflow_id], version: '1')

    Dor::Services::Client.object(pid).administrative_tags.create(tags: administrative_tags)

    render json: { pid: pid }, status: :created, location: object_location(pid)
  end

  private

  def dro_type
    case content_type_tag
    when 'Image'
      Cocina::Models::Vocab.image
    when '3D'
      Cocina::Models::Vocab.three_dimensional
    when 'Map'
      Cocina::Models::Vocab.map
    when 'Media'
      Cocina::Models::Vocab.media
    when 'Document'
      Cocina::Models::Vocab.document
    when /^Manuscript/
      Cocina::Models::Vocab.manuscript
    when 'Book (ltr)', 'Book (rtl)'
      Cocina::Models::Vocab.book
    else
      Cocina::Models::Vocab.object
    end
  end

  # helper method to get just the content type tag
  def content_type_tag
    content_tag = params[:tag].find { |tag| tag.start_with?('Process : Content Type') }
    content_tag.split(':').last.strip
  end

  # All the tags from the form except the project and content type, which are handled specially
  def administrative_tags
    params[:tag].filter { |t| !t.start_with?('Process : Content Type') && !t.start_with?('Project : ') }
  end

  # @raises [Cocina::Models::ValidationError]
  def cocina_model
    catalog_links = []
    if params[:other_id] != 'label:'
      catalog, record_id = params[:other_id].split(':')
      catalog_links = [{ catalog: catalog, catalogRecordId: record_id }]
    end

    model_params = {
      type: dro_type,
      label: params.require(:label),
      version: 1,
      administrative: {
        hasAdminPolicy: params[:admin_policy]
      },
      identification: {
        sourceId: params.require(:source_id),
        catalogLinks: catalog_links
      }
    }
    model_params[:access] = access(params[:rights]) if params[:rights] != 'default'

    structural = {}
    structural[:isMemberOf] = params[:collection] if params[:collection]
    case content_type_tag
    when 'Book (ltr)'
      structural[:hasMemberOrders] = [{ viewingDirection: 'left-to-right' }]
    when 'Book (rtl)'
      structural[:hasMemberOrders] = [{ viewingDirection: 'right-to-left' }]
    end
    model_params[:structural] = structural
    project = params[:tag].find { |t| t.start_with?('Project : ') }
    if project
      model_params[:administrative][:partOfProject] = project.sub(/^Project : /, '')
    end

    Cocina::Models::RequestDRO.new(model_params)
  end

  # @param [String] the rights representation from the form
  # @return [Hash<Symbol,String>] a hash representing the Access subschema of the Cocina model
  def access(rights)
    if rights.start_with?('loc:')
      {
        access: 'location-based',
        readLocation: rights.delete_prefix('loc:')
      }
    else
      {
        access: rights
      }
    end
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
