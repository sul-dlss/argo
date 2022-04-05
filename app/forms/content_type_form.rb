# frozen_string_literal: true

class ContentTypeForm < ApplicationChangeSet
  property :old_resource_type, virtual: true
  property :new_resource_type, virtual: true
  property :new_content_type, virtual: true

  validates :new_content_type, inclusion: {
    in: Constants::CONTENT_TYPES.keys,
    allow_blank: false
  }

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    self.old_resource_type = model.respond_to?(:structural) ? Constants::RESOURCE_TYPES.key(model.structural.contains.first&.type) : nil
    self.new_resource_type = old_resource_type
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    object_client.update(params: model.new(cocina_update_attributes))
  end

  def object_client
    Dor::Services::Client.object(model.externalIdentifier)
  end

  def cocina_update_attributes
    {}.tap do |attributes|
      attributes[:type] = Constants::CONTENT_TYPES[new_content_type]
      attributes[:structural] = if resource_types_should_change?
                                  structural_with_resource_type_changes
                                else
                                  model.structural.new(hasMemberOrders: member_orders)
                                end
    end
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
    model.structural.new(
      hasMemberOrders: member_orders,
      contains: model.structural.contains.map do |resource|
        next resource unless resource.type == Constants::RESOURCE_TYPES[old_resource_type]

        resource.new(type: Constants::RESOURCE_TYPES[new_resource_type])
      end
    )
  end

  def resource_types_should_change?
    new_resource_type.present? &&
      model.structural.contains
         .map(&:type)
         .any? { |resource_type| resource_type == Constants::RESOURCE_TYPES[old_resource_type] }
  end
end
