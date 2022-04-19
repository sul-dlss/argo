# frozen_string_literal: true

class ContentTypeForm < ApplicationChangeSet
  property :old_resource_type, virtual: true
  property :new_resource_type, virtual: true
  property :new_content_type, virtual: true
  property :viewing_direction, virtual: true

  CONTENT_TYPES = {
    'book' => Cocina::Models::ObjectType.book,
    'file' => Cocina::Models::ObjectType.object,
    'image' => Cocina::Models::ObjectType.image,
    'map' => Cocina::Models::ObjectType.map,
    'media' => Cocina::Models::ObjectType.media,
    '3d' => Cocina::Models::ObjectType.three_dimensional,
    'document' => Cocina::Models::ObjectType.document,
    'geo' => Cocina::Models::ObjectType.geo,
    'webarchive-seed' => Cocina::Models::ObjectType.webarchive_seed
  }.freeze

  DIRECTIONS = %w[right-to-left left-to-right].freeze

  validates :new_content_type, inclusion: {
    in: CONTENT_TYPES.values,
    allow_blank: false
  }

  validates :viewing_direction, inclusion: {
    in: DIRECTIONS,
    allow_blank: true
  }

  # When the object is initialized, copy the properties from the cocina model to the form:
  def setup_properties!(_options)
    return unless model.respond_to?(:structural)

    self.old_resource_type = Constants::RESOURCE_TYPES.key(model.structural.contains.first&.type)
    self.new_resource_type = old_resource_type
    self.viewing_direction = model.structural.hasMemberOrders.first&.viewingDirection
  end

  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  # @raises [Cocina::Models::ValidationError] when given invalid Cocina values or structures
  def save_model
    Repository.store(model.new(cocina_update_attributes))
  end

  def cocina_update_attributes
    {}.tap do |attributes|
      attributes[:type] = new_content_type
      attributes[:structural] = if resource_types_should_change?
                                  structural_with_resource_type_changes
                                else
                                  model.structural.new(hasMemberOrders: member_orders)
                                end
    end
  end

  # If the new content type is a book or image, we need to set the viewing direction attribute in the cocina model
  def member_orders
    return [] unless may_have_direction? && viewing_direction.present?

    [{ viewingDirection: viewing_direction }]
  end

  def may_have_direction?
    [Cocina::Models::ObjectType.book, Cocina::Models::ObjectType.image].include?(new_content_type)
  end

  def structural_with_resource_type_changes
    model.structural.new(
      hasMemberOrders: member_orders,
      contains: model.structural.contains.map do |resource|
        next resource unless resource.type == old_resource_type

        resource.new(type: new_resource_type)
      end
    )
  end

  def resource_types_should_change?
    new_resource_type.present? &&
      model.structural.contains
           .map(&:type)
           .any? { |resource_type| resource_type == old_resource_type }
  end
end
