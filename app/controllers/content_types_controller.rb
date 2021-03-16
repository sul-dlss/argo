# frozen_string_literal: true

class ContentTypesController < ApplicationController
  before_action :load_resource

  def show
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  # set the content type in the content metadata
  def update
    authorize! :manage_item, @cocina_object

    # if this object has been submitted and doesnt have an open version, they cannot change it.
    state_service = StateService.new(@cocina_object.externalIdentifier, version: @cocina_object.version)
    return render_error('Object cannot be modified in its current state.') unless state_service.allows_modification?
    return render_error('Invalid new content type.') unless valid_content_type?
    return render_error("Object doesn't contain resources to update.") unless has_content?

    cocina_update_attributes = {}.tap do |attributes|
      attributes[:type] = Constants::CONTENT_TYPES[params[:new_content_type]] if content_type_should_change?
      attributes[:structural] = structural_with_resource_type_changes if resource_types_should_change?
    end
    # byebug
    updated_cocina_object = @cocina_object.new(cocina_update_attributes)

    object_client.update(params: updated_cocina_object)
    Argo::Indexer.reindex_pid_remotely(@cocina_object.externalIdentifier) unless params[:bulk]

    respond_to do |format|
      if params[:bulk]
        format.html { render plain: 'Content type updated.' }
      else
        format.any { redirect_to solr_document_path(params[:item_id]), notice: 'Content type updated!' }
      end
    end
  end

  private

  def render_error(msg)
    render status: :forbidden, plain: msg
  end

  def structural_with_resource_type_changes
    @cocina_object.structural.new(
      contains: @cocina_object.structural.contains.map do |resource|
        return resource unless resource.type == Constants::RESOURCE_TYPES[params[:old_resource_type]]

        resource.new(type: Constants::RESOURCE_TYPES[params[:new_resource_type]])
      end
    )
  end

  def resource_types_should_change?
    @cocina_object.structural.contains.map(&:type).any? { |resource_type| resource_type == Constants::RESOURCE_TYPES[params[:old_resource_type]] }
  end

  def content_type_should_change?
    @cocina_object.type == Constants::CONTENT_TYPES[params[:old_content_type]]
  end

  def valid_content_type?
    Constants::CONTENT_TYPES.keys.include?(params[:new_content_type])
  end

  def has_content?
    @cocina_object&.structural&.contains&.size&.positive?
  end

  def object_client
    Dor::Services::Client.object(params[:item_id])
  end

  def load_resource
    raise 'missing druid' if params[:item_id].blank?

    @cocina_object = object_client.find
  end
end
