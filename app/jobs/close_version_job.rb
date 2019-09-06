# frozen_string_literal: true

##
# Job to close objects
class CloseVersionJob < GenericJob
  queue_as :default

  ##
  # A job that allows a user to specify a list of pids of objects to close
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array] :user the user
  def perform(bulk_action_id, params)
    super
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        close_object(current_druid, log)
      end
      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def close_object(pid, log)
    object = Dor.find(pid)

    unless ability.can?(:manage_item, object)
      log.puts("#{Time.current} Not authorized for #{pid}")
      return
    end
    VersionService.close(identifier: pid)
    bulk_action.increment(:druid_count_success).save
    log.puts("#{Time.current} Object successfully closed #{pid}")
  rescue StandardError => e
    log.puts("#{Time.current} Closing #{pid} failed #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
  end
end
