# frozen_string_literal: true

class Dor::ObjectsController < ApplicationController
  include ApplicationHelper # for fedora_base
  before_action :munge_parameters

  def create
    if params[:collection] && params[:collection].length == 0
      params.delete :collection
    end

    begin
      # "tag"=>["Process : Content Type : Book (ltr)", "Registered By : jcoyne85"],
      process_tag = registration_params[:tag].find { |t| t.start_with?('Process : Content Type :') }.split(' : ').last
      project_tag = registration_params[:tag].find { |t| t.start_with?('Project : ') }&.partition(' : ')&.last

      type = case process_tag
             when 'Book (rtl)', 'Book (ltr)'
               direction = process_tag.end_with?('rtl') ? 'right-to-left' : 'left-to-right'
               Cocina::Models::Vocab.book
             when 'File'
               Cocina::Models::Vocab.object
             when 'Image'
               Cocina::Models::Vocab.image
             when 'Map'
               Cocina::Models::Vocab.map
             when 'Media'
               Cocina::Models::Vocab.media
             when '3D'
               Cocina::Models::Vocab.three_dimensional
             when 'Document'
               Cocina::Models::Vocab.document
             else
               raise "unknown type #{old_type}"
             end

      model_params = {
        type: type,
        depositor: current_user.login,
        label: registration_params[:label],
        administrative: {
          hasAdminPolicy: registration_params[:admin_policy],
          partOfProject: project_tag
        },
        identification: {
          sourceId: registration_params[:source_id]
        },
        structural: {}
      }
      if registration_params[:collection]
        model_params[:structural][:collection] = registration_params[:collection]
      end
      if direction
        model_params[:structural][:hasMemberOrders] = [{ viewingDirection: direction }]
      end
      if registration_params[:other_id].start_with?('symphony:') # the alternative is ":label"
        catalog, record_id = registration_params[:other_id].split(':')
        model_params[:identification][:catalogLinks] = [{ catalog: catalog, catalogRecordId: record_id }]
      end

      model_params[:access] = { access: registration_params[:rights] } if registration_params[:rights] != 'default'
      model = Cocina::Models::RequestDRO.new(model_params)
      response = Dor::Services::Client.objects.register(params: model)
    rescue Dor::Services::Client::UnexpectedResponse => e
      return render plain: e.message, status: :conflict if e.message.start_with?('Conflict')

      return render plain: e.message, status: :bad_request
    end

    pid = response[:pid]

    Dor::Config.workflow.client.create_workflow_by_name(pid, params[:workflow_id], version: '1')

    respond_to do |format|
      format.json { render json: response, location: object_location(pid) }
      format.xml  { render xml: response, location: object_location(pid) }
      format.text { render plain: pid, location: object_location(pid) }
      format.html { redirect_to object_location(pid) }
    end
  end

  private

  # source_id and label are required parameters
  def registration_params
    hash = params.permit(:object_type, :admin_policy, :metadata_source, :rights,
                         :collection, :other_id, tag: [], seed_datastream: [])
    hash[:source_id] = params.require(:source_id)
    hash[:label] = params.require(:label)
    hash
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
