# frozen_string_literal: true

##
# Job to update rights for objects
class SetRightsJob < GenericJob
  ##
  # A job that allows a user to update the rights for a list of druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  def perform(bulk_action_id, params)
    super

    @new_rights = params[:set_rights][:rights]

    with_bulk_action_log do |log|
      raise StandardError, 'Must provide rights' if @new_rights.blank?

      update_druid_count

      pids.each do |druid|
        log.puts("#{Time.current} #{self.class}: Attempting #{druid} (bulk_action.id=#{bulk_action_id})")
        set_rights(druid, log)
      end
    end
  end

  private

  def set_rights(druid, log)
    object_client = Dor::Services::Client.object(druid)
    cocina_object = object_client.find
    return unless verify_access(cocina_object, log)

    # use dor services client to update the access
    begin
      state_service = StateService.new(druid, version: cocina_object.version)
      raise StandardError, 'Object cannot be modified in its current state.' unless state_service.allows_modification?

      form_type = cocina_object.collection? ? CollectionRightsForm : DroRightsForm
      form = form_type.new(cocina_object)
      form.validate(rights: @new_rights)
      form.save

      log.puts("#{Time.current} #{self.class}: Successfully updated rights of #{druid} (bulk_action.id=#{bulk_action.id})")
      bulk_action.increment(:druid_count_success).save
    rescue StandardError => e
      log.puts("#{Time.current} SetRights failed #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
    end
  end

  def verify_access(cocina_object, log)
    return true if ability.can?(:manage_item, cocina_object)

    log.puts("#{Time.current} Not authorized for #{cocina_object.externalIdentifier}")
    bulk_action.increment(:druid_count_fail).save
    false
  end
end
