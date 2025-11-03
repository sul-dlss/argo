# frozen_string_literal: true

# job to set new content type and resource type
class SetContentTypeJob < BulkActionJob
  def current_resource_type
    @current_resource_type ||= params[:current_resource_type]
  end

  def new_content_type
    @new_content_type ||= params[:new_content_type]
  end

  def new_resource_type
    @new_resource_type ||= params[:new_resource_type]
  end

  def viewing_direction
    @viewing_direction ||= params[:viewing_direction]
  end

  def perform_bulk_action
    if current_resource_type.blank? && new_resource_type.blank? && new_content_type.blank?
      raise 'Must provide values for types.'
    end
    if new_content_type.blank? && new_resource_type.present?
      raise 'Must provide a new content type when changing resource type.'
    end

    super
  end

  class SetContentTypeJobItem < BulkActionJobItem
    delegate :current_resource_type, :new_content_type, :new_resource_type, :viewing_direction, to: :job

    def perform
      return unless check_update_ability?

      # collections, APOs, and agreements do not have content types
      return failure!(message: "Object is a #{cocina_object.type} and cannot be updated") unless cocina_object.dro?

      open_new_version_if_needed!(description: 'Updated content type')

      # use dor services client to pass a hash for structural metadata and update the cocina object
      @cocina_object = cocina_object.new(cocina_update_attributes)
      Repository.store(cocina_object)
      close_version_if_needed!

      success!(message: 'Successfully updated content type')
    end

    private

    def cocina_update_attributes
      {}.tap do |attributes|
        attributes[:type] = new_content_type
        attributes[:structural] = if resource_types_should_change?
                                    structural_with_resource_type_changes
                                  else
                                    cocina_object.structural.new(hasMemberOrders: member_orders)
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
      cocina_object.structural.new(
        hasMemberOrders: member_orders,
        contains: Array(cocina_object.structural&.contains).map do |resource|
          next resource unless resource.type == current_resource_type

          resource.new(type: new_resource_type)
        end
      )
    end

    def resource_types_should_change?
      Array(cocina_object.structural&.contains).map(&:type).any?(current_resource_type)
    end
  end
end
