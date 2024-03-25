# frozen_string_literal: true

##
# job to refresh the descriptive metadata from ILS (Folio)
class RefreshModsJob < GenericJob
  def perform(bulk_action_id, params)
    super

    with_items(params[:druids], name: 'Refresh MODS') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      catalog_record_id = cocina_object.identification&.catalogLinks&.find do |link|
                            link.catalog == CatalogRecordId.type
                          end&.catalogRecordId
      if catalog_record_id.blank?
        next failure.call("Did not update metadata because it doesn't have a #{CatalogRecordId.label}")
      end

      cocina_object = open_new_version_if_needed(cocina_object, version_message)

      Dor::Services::Client.object(cocina_object.externalIdentifier).refresh_descriptive_metadata_from_ils
      success.call('Successfully updated metadata')
    end
  end

  private

  def version_message
    'Refresh metadata from FOLIO'
  end
end
