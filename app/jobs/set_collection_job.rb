# frozen_string_literal: true

##
# job to move assign object to a new collection
class SetCollectionJob < GenericJob
  attr_reader :new_collection_ids

  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [String] :new_collection_id
  def perform(bulk_action_id, params)
    super

    @new_collection_ids = Array(params['new_collection_id'].presence)

    with_items(params[:druids], name: 'Set collection') do |cocina_object, success, _failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      cocina_object = open_new_version_if_needed(cocina_object, version_message(new_collection_ids))

      change_set = ItemChangeSet.new(cocina_object)
      change_set.validate(collection_ids: new_collection_ids)
      change_set.save

      success.call('Update successful')
    end
  end

  private

  def version_message(collection_ids)
    collection_ids ? "Added to collections #{collection_ids.join(',')}." : 'Removed collection membership.'
  end
end
