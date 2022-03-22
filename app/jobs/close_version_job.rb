# frozen_string_literal: true

##
# Job to close objects
class CloseVersionJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids of objects to close
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array] :user the user
  def perform(bulk_action_id, params)
    super
    with_bulk_action_log do |log|
      update_druid_count

      druids.each do |current_druid|
        close_object(current_druid, log)
      end
    end
  end

  private

  def close_object(druid, log)
    cocina = Dor::Services::Client.object(druid).find

    unless ability.can?(:manage_item, cocina)
      log.puts("#{Time.current} Not authorized for #{druid}")
      return
    end
    VersionService.close(identifier: druid)
    bulk_action.increment(:druid_count_success).save
    log.puts("#{Time.current} Object successfully closed #{druid}")
  rescue StandardError => e
    log.puts("#{Time.current} Closing #{druid} failed #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
  end
end
