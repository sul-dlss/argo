# frozen_string_literal: true

##
# Job to update/add source IDs to objects
class SetSourceIdsCsvJob < GenericJob
  ##
  # A job that allows a user to specify a list of pids and a list of catkeys to be associated with these pids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file The file that contains the list of druids and catkeys
  def perform(bulk_action_id, params)
    super

    # source_ids are nil if not selected for use.
    update_pids, source_ids = params_from(params)

    with_bulk_action_log do |log|
      update_druid_count(count: update_pids.count)
      update_pids.each_with_index do |current_druid, i|
        update_one(current_druid, source_ids[i], log)
      rescue StandardError => e
        log.puts("#{Time.current} Unexpected error setting source_id for #{current_druid}: #{e.message}")
        bulk_action.increment(:druid_count_fail).save
      end
    end
  end

  private

  def update_one(current_druid, source_id, log)
    cocina_object = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina_object)
      log.puts("#{Time.current} Not authorized for #{cocina_object.externalIdentifier}")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    state_service = StateService.new(cocina_object.externalIdentifier, version: cocina_object.version)
    unless state_service.allows_modification?
      new_version = open_new_version(cocina_object.externalIdentifier, cocina_object.version, version_message(source_id))
      cocina_object = cocina_object.new(version: new_version.to_i)
    end

    change_set_class = cocina_object.collection? ? CollectionChangeSet : ItemChangeSet
    change_set = change_set_class.new(cocina_object)
    if change_set.validate(source_id: source_id)
      update_source_ids(change_set, log) if change_set.changed?
    else
      log.puts("#{Time.current} #{change_set.errors.full_messages.to_sentence}")
      bulk_action.increment(:druid_count_fail).save
    end
  end

  def params_from(params)
    update_pids = []
    source_ids = []
    CSV.parse(params[:csv_file], headers: true).each do |row|
      update_pids << row['druid']
      source_ids << row['source_id']
    end
    [update_pids, source_ids]
  end

  def update_source_ids(change_set, log)
    cocina_object = change_set.model
    log.puts("#{Time.current} Beginning set source_id for #{cocina_object.externalIdentifier}")

    log_update(change_set, log)

    change_set.save
    bulk_action.increment(:druid_count_success).save
    log.puts("#{Time.current} Source ID added/updated/removed successfully")
  end

  def log_update(change_set, log)
    verb = change_set.source_id ? 'Adding' : 'Removing'
    log.puts("#{Time.current} #{verb} source ID of #{change_set.source_id}")
  end

  def version_message(source_id)
    source_id ? "Source ID updated to #{source_id}." : 'Source ID removed.'
  end
end
