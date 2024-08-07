# frozen_string_literal: true

# job to set new content type and resource type
class SetContentTypeJob < GenericJob
  def perform(bulk_action_id, params)
    super

    # types are the label for content types, e.g. book
    @current_resource_type = params[:current_resource_type]
    @new_content_type = params[:new_content_type]
    @new_resource_type = params[:new_resource_type]
    @viewing_direction = params[:viewing_direction]

    if @current_resource_type.blank? && @new_resource_type.blank? && @new_content_type.blank?
      raise 'Must provide values for types.'
    end
    if @new_content_type.blank? && @new_resource_type.present?
      raise 'Must provide a new content type when changing resource type.'
    end

    with_items(params[:druids], name: 'Set content types') do |cocina_object, success, failure|
      set_content_type(cocina_object, success, failure)
    end
  end

  private

  attr_reader :current_resource_type, :new_content_type, :new_resource_type

  def set_content_type(cocina_object, success, failure)
    # collections, APOs, and agreements do not have content types
    if [Cocina::Models::ObjectType.collection, Cocina::Models::ObjectType.admin_policy].include? cocina_object.type
      return failure.call("Object is a #{cocina_object.type} and cannot be updated")
    end

    return failure.call('Not authorized') unless ability.can?(:update, cocina_object)

    return failure.call('Object cannot be modified in its current state.') unless VersionService.open?(druid: cocina_object.externalIdentifier)

    # use dor services client to pass a hash for structural metadata and update the cocina object
    new_model = cocina_object.new(cocina_update_attributes(cocina_object))
    Repository.store(new_model)
    success.call('Successfully updated content type')
  end

  def cocina_update_attributes(cocina_object)
    {}.tap do |attributes|
      attributes[:type] = @new_content_type
      attributes[:structural] = if resource_types_should_change?(cocina_object)
                                  structural_with_resource_type_changes(cocina_object)
                                else
                                  cocina_object.structural.new(hasMemberOrders: member_orders)
                                end
    end
  end

  # If the new content type is a book or image, we need to set the viewing direction attribute in the cocina model
  def member_orders
    return [] unless may_have_direction? && @viewing_direction.present?

    [{ viewingDirection: @viewing_direction }]
  end

  def may_have_direction?
    [Cocina::Models::ObjectType.book, Cocina::Models::ObjectType.image].include?(@new_content_type)
  end

  def structural_with_resource_type_changes(cocina_object)
    cocina_object.structural.new(
      hasMemberOrders: member_orders,
      contains: Array(cocina_object.structural&.contains).map do |resource|
        next resource unless resource.type == @current_resource_type

        resource.new(type: @new_resource_type)
      end
    )
  end

  def resource_types_should_change?(cocina_object)
    Array(cocina_object.structural&.contains).map(&:type).any?(@current_resource_type)
  end
end
