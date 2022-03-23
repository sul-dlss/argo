# frozen_string_literal: true

##
# Job to open objects
class PrepareJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids of objects to open
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required because groups are not persisted with the user.
  # @option params [Array] :user the user
  # @option params [String] :significance
  # @option params [String] :version_description
  def perform(bulk_action_id, params)
    super

    significance = params['significance']
    description = params['version_description']

    with_bulk_action_log do |log|
      update_druid_count

      druids.each do |current_druid|
        open_object(current_druid, significance, description, @current_user.to_s, log)
      end
    end
  end

  private

  def open_object(druid, significance, description, user_name, log)
    cocina = Dor::Services::Client.object(druid).find

    return log.puts("#{Time.current} #{druid} is not openable") unless openable?(druid, version: cocina.version)

    return log.puts("#{Time.current} Not authorized for #{druid}") unless ability.can?(:manage_item, cocina)

    VersionService.open(identifier: druid,
                        significance: significance,
                        description: description,
                        opening_user_name: user_name)
    bulk_action.increment(:druid_count_success).save
    log.puts("#{Time.current} Object successfully opened #{druid}")
  rescue StandardError => e
    log.puts("#{Time.current} Opening #{druid} failed #{e.class} #{e.message}")
    bulk_action.increment(:druid_count_fail).save
  end

  def openable?(druid, version:)
    DorObjectWorkflowStatus.new(druid, version: version).can_open_version?
  end
end
