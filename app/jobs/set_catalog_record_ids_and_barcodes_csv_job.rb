# frozen_string_literal: true

##
# Job to update/add catalog record IDs/barcodes to objects
class SetCatalogRecordIdsAndBarcodesCsvJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids and a list of catalog record IDs to be associated with these druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of
  # @option params [String] :catalog_record_ids list of catalog record IDs to be associated 1:1 with druids in order
  # @option params [String] :use_catalog_record_ids_option option to update the catalog_record_ids
  # @option params [String] :barcodes list of barcodes to be associated 1:1 with druids in order
  # @option params [String] :use_barcodes_option option to update the barcodes
  # @option params [String] :csv_file CSV string
  def perform(bulk_action_id, params)
    super

    with_csv_items(
      CSV.parse(params[:csv_file], headers: true),
      name: 'Set Catalog Record IDs and Barcodes'
    ) do |cocina_object, row, success, failure, _row_number, log| # rubocop:disable Metrics/ParameterLists
      change_set = change_set_for(cocina_object)
      change_set_params = change_set_params_from(row, cocina_object)

      if change_set.validate(change_set_params)
        next success.call('No changes specified for object') unless change_set.changed?
        next failure.call('Not authorized to update this object') unless ability.can?(:update, cocina_object)

        log_update(change_set, log)

        new_cocina_model = open_new_version_if_needed(cocina_object, version_message(change_set))
        new_change_set = change_set_for(new_cocina_model)
        new_change_set.validate(change_set_params)
        new_change_set.save

        success.call("#{CatalogRecordId.label}/barcode added/updated/removed successfully")
      else
        failure.call("Invalid #{CatalogRecordId.label}/barcode for the object: #{change_set.errors.full_messages.to_sentence}")
      end
    end
  end

  private

  def change_set_params_from(row, cocina_object)
    {}.tap do |change_set_params|
      change_set_params[:barcode] = row['barcode'] if row.header?('barcode') && cocina_object.dro?

      if row.header?(CatalogRecordId.csv_header)
        change_set_params[:catalog_record_ids] = begin
          catalog_record_id_column_indices = row.headers.each_index.select { |index| row.headers[index] == CatalogRecordId.csv_header }
          row.fields(*catalog_record_id_column_indices).compact
        end

        change_set_params[:refresh] = row['refresh']&.downcase != 'false'
        change_set_params[:part_label] = row['part_label']&.strip
        change_set_params[:sort_key] = row['sort_key']&.strip
      end
    end
  end

  def change_set_for(cocina_object)
    change_set_class = cocina_object.dro? ? ItemChangeSet : CollectionChangeSet
    change_set_class.new(cocina_object)
  end

  def log_update(change_set, log)
    if change_set.changed?(:catalog_record_ids)
      if change_set.catalog_record_ids.present?
        log.puts("#{Time.current} Adding #{CatalogRecordId.label} of #{change_set.catalog_record_ids.join(', ')}")
      else
        log.puts("#{Time.current} Removing #{CatalogRecordId.label}")
      end
    end
    return unless change_set.changed?(:barcode)

    if change_set.barcode
      log.puts("#{Time.current} Adding barcode of #{change_set.barcode}")
    else
      log.puts("#{Time.current} Removing barcode")
    end
  end

  def version_message(change_set)
    # Yes, this is a private API, but it seems this is what the gem maintainers want folks to use:
    #   https://github.com/apotonick/disposable/issues/57#issuecomment-268738396
    changed_properties = change_set.instance_variable_get(:@_changes).select { |_property, changed| changed == true }.keys

    return [] if changed_properties.blank?

    changed_properties.map do |property|
      change = change_set.public_send(property)
      if change.present?
        "#{property.humanize} updated to #{Array(change).join(', ')}."
      else
        "#{property.humanize} removed."
      end
    end

    changed_properties.join(' ')
  end
end
