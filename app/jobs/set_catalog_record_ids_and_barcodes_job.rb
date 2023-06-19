# frozen_string_literal: true

##
# Job to update/add catalog source IDs/barcodes to objects
class SetCatalogRecordIdsAndBarcodesJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids and a list of catalog record IDs to be associated with these druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of
  # @option params [String] :catalog_record_ids list of catalog record IDs to be associated 1:1 with druids in order
  # @option params [String] :use_catalog_record_ids_option option to update the catalog_record_ids
  # @option params [String] :barcodes list of barcodes to be associated 1:1 with druids in order
  # @option params [String] :use_barcodes_option option to update the barcodes
  def perform(bulk_action_id, params)
    super

    # Catalog record IDs, barcodes are nil if not selected for use.
    update_druids, catalog_record_ids, barcodes, refresh = params_from(params)

    with_bulk_action_log do |log|
      update_druid_count(count: update_druids.count)
      update_druids.each_with_index do |current_druid, i|
        cocina_object = Repository.find(current_druid)
        args = {}
        args[:catalog_record_ids] = Array(catalog_record_ids[i]) if catalog_record_ids
        args[:refresh] = refresh[i] if refresh
        args[:barcode] = barcodes[i] if barcodes && cocina_object.dro?
        change_set = change_set_for(cocina_object)
        if change_set.validate(args)
          update_catalog_record_id_and_barcode(change_set, args, log) if change_set.changed?
        else
          log.puts("#{Time.current} Invalid #{CatalogRecordId.label}/barcode for #{cocina_object.externalIdentifier}")
          bulk_action.increment(:druid_count_fail).save
        end
      end
    end
  end

  protected

  def params_from(params)
    catalog_record_ids = catalog_record_ids_from_params(params)
    refresh = catalog_record_ids ? Array.new(catalog_record_ids.size, true) : nil
    barcodes = barcodes_from_params(params)
    [druids, catalog_record_ids, barcodes, refresh]
  end

  private

  def update_catalog_record_id_and_barcode(change_set, args, log)
    cocina_object = change_set.model
    log.puts("#{Time.current} Beginning SetCatalogRecordIdsAndBarcodesJob for #{cocina_object.externalIdentifier}")

    unless ability.can?(:update, cocina_object)
      log.puts("#{Time.current} Not authorized for #{cocina_object.externalIdentifier}")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    log_update(change_set, log)

    begin
      new_cocina_model = open_new_version_if_needed(cocina_object, version_message(change_set))
      new_change_set = change_set_for(new_cocina_model)
      new_change_set.validate(args)
      new_change_set.save

      bulk_action.increment(:druid_count_success).save
      log.puts("#{Time.current} #{CatalogRecordId.label}/barcode added/updated/removed successfully")
    rescue => e
      log.puts("#{Time.current} #{CatalogRecordId.label}/barcode failed #{e.class} #{e.message}")
      Honeybadger.context(args:, druid: cocina_object.externalIdentifier)
      Honeybadger.notify(e)
      bulk_action.increment(:druid_count_fail).save
      nil
    end
  end

  def change_set_for(cocina_object)
    change_set_class = cocina_object.dro? ? ItemChangeSet : CollectionChangeSet
    change_set_class.new(cocina_object)
  end

  def catalog_record_ids_from_params(params)
    return unless params["use_catalog_record_ids_option"] == "1"

    lines_for(params, :catalog_record_ids).map { |line| line.split(",") }
  end

  def barcodes_from_params(params)
    return unless params["use_barcodes_option"] == "1"

    lines_for(params, :barcodes).map(&:strip).map(&:presence)
  end

  # This will preserve the blank lines as nils, which indicate that a catalog record ID/barcode should be removed.
  def lines_for(params, key)
    params.fetch(key).split("\n")
  end

  def log_update(change_set, log)
    if change_set.changed?(:catalog_record_ids)
      if change_set.catalog_record_ids.present?
        log.puts("#{Time.current} Adding #{CatalogRecordId.label} of #{change_set.catalog_record_ids.join(", ")}")
      else
        log.puts("#{Time.current} Removing #{CatalogRecordId.label}")
      end
    end
    if change_set.changed?(:barcode)
      if change_set.barcode
        log.puts("#{Time.current} Adding barcode of #{change_set.barcode}")
      else
        log.puts("#{Time.current} Removing barcode")
      end
    end
  end

  def version_message(change_set)
    msgs = []
    if change_set.changed?(:catalog_record_ids)
      msgs << if change_set.catalog_record_ids.present?
        "#{CatalogRecordId.label} updated to #{change_set.catalog_record_ids.join(", ")}."
      else
        "#{CatalogRecordId.label} removed."
      end
    end
    if change_set.changed?(:barcode)
      msgs << if change_set.barcode
        "Barcode updated to #{change_set.barcode}."
      else
        "Barcode removed."
      end
    end
    msgs.join(" ")
  end
end
