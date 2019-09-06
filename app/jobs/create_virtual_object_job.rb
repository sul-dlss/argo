# frozen_string_literal: true

##
# job to create virtual objects
class CreateVirtualObjectJob < GenericJob
  include ValueHelper

  queue_as :default

  ##
  # A job that creates a virtual object
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check (can_manage?)
  # @option params [Array] :user the user
  # @option params [Hash] :create_virtual_object parameters for the create_virtual_object job (:parent_druid, :child_druids)
  def perform(bulk_action_id, params)
    super

    parent_druid = params[:create_virtual_object][:parent_druid]
    child_druids = pids_with_prefix(params[:create_virtual_object][:child_druids])

    return unless authorized_to_manage?(parent_druid)

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")

      # NOTE: We use this instead of `update_druid_count` because virtual object
      #       creation does not use the `pids` form field.
      bulk_action.update(druid_count_total: child_druids.length)

      begin
        client = Dor::Services::Client.object(parent_druid)
        client.add_constituents(child_druids: child_druids)
        ([parent_druid] + child_druids).each do |druid|
          VersionService.close(identifier: druid)
          bulk_action.increment(:druid_count_success).save
          log.puts("#{Time.current} Closing version of #{druid}")
        end
      rescue Dor::Services::Client::UnexpectedResponse => e
        bulk_action.update(druid_count_fail: child_druids.length)
        log.puts("#{Time.current} Creating virtual object #{parent_druid} failed because one or more objects are not combinable: #{errors_from(e.message)}")
      rescue StandardError => e
        bulk_action.update(druid_count_fail: child_druids.length)
        log.puts("#{Time.current} Creating virtual object #{parent_druid} failed for an unexpected reason: #{e.class} #{e.message}")
      end

      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def authorized_to_manage?(druid)
    current_obj = Dor.find(druid)
    return true if ability.can?(:manage_item, current_obj)

    false
  end

  def errors_from(error_string)
    # error_string looks like:
    #   Unprocessable Entity: 422 ({"errors":{"druid:kv840rx2720":"Item druid:kv840rx2720 is dark","druid:xb482bw3979":"Item druid:xb482bw3979 is dark"}})
    matches = error_string.match(/(?<status_text>\w+): (?<status_code>\d+) \((?<error_json>.+)\)/)
    error_hash = JSON.parse(matches[:error_json])['errors']
    "#{error_hash.size} objects could not be combined: #{error_hash.values.to_sentence}"
  end
end
