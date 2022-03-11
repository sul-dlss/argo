# frozen_string_literal: true

##
# job to move assign object to a new collection
class SetCollectionJob < GenericJob
  attr_reader :new_collection_ids

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of pids
  # @option params [String] :new_collection_id
  def perform(bulk_action_id, params)
    super

    @new_collection_ids = Array(params['new_collection_id'].presence)

    with_bulk_action_log do |log|
      update_druid_count

      pids.each do |current_druid|
        log.puts("#{Time.current} SetCollectionJob: Starting update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
        set_collection_and_index_safely(current_druid, log)
        log.puts("#{Time.current} SetCollectionJob: Finished update for #{current_druid} (bulk_action.id=#{bulk_action_id})")
      end
    end
  end

  private

  def set_collection_and_index_safely(current_druid, log)
    cocina_object = Dor::Services::Client.object(current_druid).find
    state_service = StateService.new(current_druid, version: cocina_object.version)
    check_can_set_collection!(cocina_object, state_service)
    unless state_service.allows_modification?
      new_version = open_new_version(cocina_object.externalIdentifier, cocina_object.version, version_message(new_collection_ids))
      cocina_object = cocina_object.new(version: new_version.to_i)
    end

    change_set = ItemChangeSet.new(cocina_object)
    change_set.validate(collection_ids: new_collection_ids)
    change_set.save

    log.puts("#{Time.current} SetCollectionJob: Successfully updated #{cocina_object.externalIdentifier} (bulk_action.id=#{bulk_action.id})")
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log.puts("#{Time.current} SetCollectionJob: Unexpected error for #{current_druid} (bulk_action.id=#{bulk_action.id}): #{e} #{e.backtrace}")
    bulk_action.increment(:druid_count_fail).save
  end

  def check_can_set_collection!(cocina, state_service)
    raise "#{cocina.externalIdentifier} is not open for modification" unless state_service.allows_modification?

    raise "user not authorized to modify #{cocina.externalIdentifier}" unless ability.can?(:manage_item, cocina)
  end

  def version_message(collection_ids)
    collection_ids ? "Added to collections #{collection_ids.join(',')}." : 'Removed collection membership.'
  end
end
