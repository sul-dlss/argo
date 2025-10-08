# frozen_string_literal: true

##
# job to move assign object to a new collection
class SetCollectionJob < BulkActionJob
  def collection_ids
    @collection_ids ||= Array(params['new_collection_id'].presence)
  end

  class SetCollectionJobItem < BulkActionJobItem
    delegate :collection_ids, to: :job

    def perform
      return unless check_update_ability?

      open_new_version_if_needed!(description: version_message)

      change_set.validate(collection_ids:)
      change_set.save

      success!(message: 'Update successful')
    end

    def change_set
      @change_set ||= ItemChangeSet.new(cocina_object)
    end

    def version_message
      collection_ids ? "Added to collections #{collection_ids.join(',')}." : 'Removed collection membership.'
    end
  end
end
