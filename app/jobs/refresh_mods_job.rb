# frozen_string_literal: true

##
# job to refresh the descriptive metadata from ILS (Folio)
class RefreshModsJob < BulkActionJob
  class RefreshModsJobItem < BulkActionJobItem
    def perform
      return unless check_update_ability?

      return failure!(message: "Does not have a #{CatalogRecordId.label}") if catalog_record_id.blank?

      open_new_version_if_needed!(description: 'Refreshed metadata from FOLIO')

      Dor::Services::Client.object(druid).refresh_descriptive_metadata_from_ils
      close_version_if_needed!

      success!(message: 'Successfully updated metadata')
    end

    def catalog_record_id
      @catalog_record_id ||= cocina_object.identification&.catalogLinks&.find do |link|
        link.catalog == CatalogRecordId.type
      end&.catalogRecordId
    end
  end
end
