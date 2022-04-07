# frozen_string_literal: true

##
# Job to update/add source IDs to objects
class SetSourceIdsCsvJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids and a list of catkeys to be associated with these druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file The file that contains the list of druids and catkeys
  def perform(bulk_action_id, params)
    super

    # source_ids are nil if not selected for use.
    update_druids, source_ids = params_from(params)

    with_bulk_action_log do |log|
      update_druid_count(count: update_druids.count)
      update_druids.each_with_index do |current_druid, i|
        update_one(current_druid, source_ids[i], log)
      rescue StandardError => e
        log.puts("#{Time.current} Unexpected error setting source_id for #{current_druid}: #{e.message}")
        bulk_action.increment(:druid_count_fail).save
      end
    end
  end

  private

  def update_one(current_druid, source_id, log)
    item = Repository.find(current_druid)

    unless ability.can?(:manage_item, item)
      log.puts("#{Time.current} Not authorized for #{item.id}")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    state_service = StateService.new(item)
    unless state_service.allows_modification?
      new_version = open_new_version(item.id, item.version, version_message(source_id))
      item.version = new_version.to_i
    end

    change_set_class = item.is_a?(Collection) ? CollectionChangeSet : ItemChangeSet
    change_set = change_set_class.new(item)
    if change_set.validate(source_id: source_id)
      update_source_ids(change_set, log) if change_set.changed?
    else
      log.puts("#{Time.current} #{change_set.errors.full_messages.to_sentence}")
      bulk_action.increment(:druid_count_fail).save
    end
  end

  def params_from(params)
    update_druids = []
    source_ids = []
    CSV.parse(params[:csv_file], headers: true).each do |row|
      update_druids << row['druid']
      source_ids << row['source_id']
    end
    [update_druids, source_ids]
  end

  def update_source_ids(change_set, log)
    item = change_set.model
    log.puts("#{Time.current} Beginning set source_id for #{item.id}")

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
