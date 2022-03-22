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

    object_client.update(params: @cocina_object.new(cocina_update_attributes))
    Argo::Indexer.reindex_pid_remotely(@cocina_object.externalIdentifier)

    redirect_to solr_document_path(params[:item_id]), notice: 'Content type updated!'
  end

  private

  def render_error(msg)
    render status: :forbidden, plain: msg
  end

  def cocina_update_attributes
    {}.tap do |attributes|
      attributes[:type] = Constants::CONTENT_TYPES[new_content_type]
      attributes[:structural] = if resource_types_should_change?
                                  structural_with_resource_type_changes
                                else
                                  @cocina_object.structural.new(hasMemberOrders: member_orders)
                                end
    end
  end

  def old_resource_type
    return '' if [Cocina::Models::ObjectType.collection, Cocina::Models::ObjectType.admin_policy].include? @cocina_object.type

    Constants::RESOURCE_TYPES.key(@cocina_object.structural.contains&.first&.type) || ''
  end

  def new_content_type
    params[:new_content_type]
  end

  # If the new content type is a book, we need to set the viewing direction attribute in the cocina model
  def member_orders
    return [] unless new_content_type.start_with?('book')

    viewing_direction = if new_content_type == 'book (ltr)'
                          'left-to-right'
                        else
                          'right-to-left'
                        end
    [{ viewingDirection: viewing_direction }]
  end

  def structural_with_resource_type_changes
    @cocina_object.structural.new(
      hasMemberOrders: member_orders,
      contains: Array(@cocina_object.structural&.contains).map do |resource|
        next resource unless resource.type == Constants::RESOURCE_TYPES[params[:old_resource_type]]

        resource.new(type: Constants::RESOURCE_TYPES[params[:new_resource_type]])
      end
    )
  end

  def resource_types_should_change?
    Array(@cocina_object.structural&.contains).map(&:type).any? { |resource_type| resource_type == Constants::RESOURCE_TYPES[params[:old_resource_type]] }
  end

  def valid_content_type?
    Constants::CONTENT_TYPES.keys.include?(new_content_type)
  end

  def object_client
    Dor::Services::Client.object(params[:item_id])
  end

  def load_resource
    raise 'missing druid' if params[:item_id].blank?

    @cocina_object = object_client.find
    @old_resource_type = old_resource_type
  end
end
