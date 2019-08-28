# frozen_string_literal: true

##
# Job to open objects
class PrepareJob < GenericJob
  queue_as :default

  ##
  # A job that allows a user to specify a list of pids of objects to open
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check (can_manage?)
  # @option params [Array] :user the user
  # @option params [Hash] :prepare parameters for the prepare job (:severity and :description)
  def perform(bulk_action_id, params)
    super

    severity = params[:prepare]['severity']
    description = params[:prepare]['description']

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        open_object(current_druid, severity, description, @current_user.to_s, log)
      end
      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def open_object(pid, severity, description, user_name, log)
    return log.puts("#{Time.current} #{pid} is not openable") unless openable?(pid)

    info = {
      significance: severity,
      description: description,
      opening_user_name: user_name
    }
    VersionService.open(identifier: pid, vers_md_upd_info: info)
    bulk_action.increment(:druid_count_success).save
    log.puts("#{Time.current} Object successfully opened #{pid}")
  rescue StandardError => e
    log.puts("#{Time.current} Opening #{pid} failed #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
  end

  def openable?(pid)
    DorObjectWorkflowStatus.new(pid).can_open_version?
  end
end
