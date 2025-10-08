# frozen_string_literal: true

##
# Job to update/add source IDs to objects
class SetSourceIdsCsvJob < BulkActionCsvJob
  class SetSourceIdsCsvJobItem < BulkActionCsvJobItem
    attr_reader :change_set

    def perform
      return unless check_update_ability?

      @change_set = build_change_set
      return failure!(message: change_set.errors.full_messages.to_sentence) unless change_set.validate(source_id:)
      return success!(message: 'No changes to source ID') unless change_set.changed?

      open_new_version_if_needed!(description: 'Set source ID')

      @change_set = build_change_set # Rebuild with the new cocina model
      change_set.validate(source_id:)
      change_set.save

      success!(message: 'Source ID added/updated/removed successfully')
    end

    private

    def build_change_set
      (cocina_object.collection? ? CollectionChangeSet : ItemChangeSet).new(cocina_object)
    end

    def source_id
      row['source_id']
    end
  end
end
