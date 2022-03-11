# frozen_string_literal: true

# rubocop:disable Metrics/CyclomaticComplexity
# job to set new content type and resource type
class SetContentTypeJob < GenericJob
  def perform(bulk_action_id, params)
    super

    # types are the label for content types, e.g. book (ltr)
    @current_resource_type = params[:current_resource_type]
    @new_content_type = params[:new_content_type]
    @new_resource_type = params[:new_resource_type]

    with_bulk_action_log do |log_buffer|
      raise StandardError, 'Must provide values for types.' if @current_resource_type.blank? && @new_resource_type.blank? && @new_content_type.blank?
      raise StandardError, 'Must provide a new content type when changing resource type.' if @new_content_type.blank? && @new_resource_type.present?

      update_druid_count

      pids.each do |current_druid|
        log_buffer.puts("#{Time.current} #{self.class}: Attempting #{current_druid} (bulk_action.id=#{bulk_action_id})")
        set_content_type(current_druid, log_buffer)
      end
    rescue StandardError => e
      log_buffer.puts "#{Time.current} #{self.class}: Error with form values provided: #{e.message}"
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  attr_reader :current_resource_type, :new_content_type, :new_resource_type

  def set_content_type(current_druid, log_buffer)
    object_client = Dor::Services::Client.object(current_druid)
    cocina_object = object_client.find

    # collections, APOs, and agreements do not have content types
    if [Cocina::Models::ObjectType.collection, Cocina::Models::ObjectType.admin_policy].include? cocina_object.type
      log_buffer.puts "#{Time.current} #{self.class}: Could not update content type for #{current_druid}: object is a #{cocina_object.type}"
      bulk_action.increment(:druid_count_fail).save
      return
    end

    return unless verify_access(cocina_object, log_buffer)

    # use dor services client to pass a hash for structural metadata and update the cocina object
    begin
      state_service = StateService.new(cocina_object.externalIdentifier, version: cocina_object.version)
      raise StandardError, 'Object cannot be modified in its current state.' unless state_service.allows_modification?

      object_client.update(params: cocina_object.new(cocina_update_attributes(cocina_object)))
      Argo::Indexer.reindex_pid_remotely(cocina_object.externalIdentifier)
      log_buffer.puts("#{Time.current} #{self.class}: Successfully updated content type of #{current_druid} (bulk_action.id=#{bulk_action.id})")
      bulk_action.increment(:druid_count_success).save
    rescue StandardError => e
      log_buffer.puts "#{Time.current} #{self.class}: Unexpected error for #{current_druid}: (bulk_action.id=#{bulk_action.id}): #{e.message}"
      bulk_action.increment(:druid_count_fail).save
    end
  end

  def verify_access(cocina_object, log_buffer)
    return true if ability.can?(:manage_item, cocina_object)

    log_buffer.puts("#{Time.current} Not authorized for #{cocina_object.externalIdentifier}")
    bulk_action.increment(:druid_count_fail).save
    false
  end

  def cocina_update_attributes(cocina_object)
    {}.tap do |attributes|
      attributes[:type] = Constants::CONTENT_TYPES[@new_content_type]
      attributes[:structural] = if resource_types_should_change?(cocina_object)
                                  structural_with_resource_type_changes(cocina_object)
                                else
                                  cocina_object.structural.new(hasMemberOrders: member_orders)
                                end
    end
  end

  # If the new content type is a book, we need to set the viewing direction attribute in the cocina model
  def member_orders
    return [] unless @new_content_type.start_with?('book')

    viewing_direction = if @new_content_type == 'book (ltr)'
                          'left-to-right'
                        else
                          'right-to-left'
                        end
    [{ viewingDirection: viewing_direction }]
  end

  def structural_with_resource_type_changes(cocina_object)
    cocina_object.structural.new(
      hasMemberOrders: member_orders,
      contains: Array(cocina_object.structural&.contains).map do |resource|
        next resource unless resource.type == Constants::RESOURCE_TYPES[@current_resource_type]

        resource.new(type: Constants::RESOURCE_TYPES[@new_resource_type])
      end
    )
  end

  def resource_types_should_change?(cocina_object)
    Array(cocina_object.structural&.contains).map(&:type).any? { |resource_type| resource_type == Constants::RESOURCE_TYPES[@current_resource_type] }
  end
end
