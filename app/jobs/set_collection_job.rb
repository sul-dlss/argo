# frozen_string_literal: true

##
# job to move assign object to a new collection
class SetCollectionJob < GenericJob
  attr_reader :new_collection_ids

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [Hash] :set_collection
  def perform(bulk_action_id, params)
    super

    @new_collection_ids = [params[:set_collection]['new_collection_id']]

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting SetCollectionJob for BulkAction #{bulk_action_id}")
      update_druid_count

      pids.each do |current_druid|
        log.puts("#{Time.current} SetCollectionJob: Starting update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
        set_collection_and_index_safely(current_druid, log)
        log.puts("#{Time.current} SetGoverningApoJob: Finished update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
      end

      log.puts("#{Time.current} Finished SetGoverningApoJob for BulkAction #{bulk_action_id}")
    end
  end

  private

  def set_collection_and_index_safely(current_druid, log)
    cocina_item = Dor::Services::Client.object(current_druid).find
    state_service = StateService.new(current_druid, version: cocina_item.version)
    check_can_set_collection!(cocina_item, state_service)
    open_new_version(current_druid, cocina_item.version, 'Set collection') unless state_service.allows_modification?

    change_set = ItemChangeSet.new(cocina_item)
    change_set.validate(collection_ids: new_collection_ids)
    change_set.save
    Argo::Indexer.reindex_pid_remotely(current_druid)

    log.puts("#{Time.current} SetCollectionJob: Successfully updated #{current_druid} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log.puts("#{Time.current} SetCollectionJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e} #{e.backtrace}")
    bulk_action.increment(:druid_count_fail).save
  end

  def check_can_set_collection!(cocina, state_service)
    raise "#{cocina.externalIdentifier} is not open for modification" unless state_service.allows_modification?

    new_collection_ids.each do |new_collection_id|
      raise "user not authorized to move #{cocina.externalIdentifier} to #{new_collection_ids}" unless ability.can?(:manage_item, cocina, new_collection_id)
    end
  end
end
