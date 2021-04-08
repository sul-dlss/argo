# frozen_string_literal: true

##
# Job to update/add catkey/barcodes to objects
class SetCatkeysAndBarcodesJob < GenericJob
  ##
  # A job that allows a user to specify a list of pids and a list of catkeys to be associated with these pids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of
  # @option params [String] :catkeys list of catkeys to be associated 1:1 with pids in order
  # @option params [String] :use_catkeys_option option to update the catkeys
  # @option params [String] :barcodes list of barcodes to be associated 1:1 with pids in order
  # @option params [String] :use_barcodes_option option to update the barcodes
  def perform(bulk_action_id, params)
    super

    # Catkeys, barcodes are nil if not selected for use.
    update_pids, catkeys, barcodes = params_from(params)

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting SetCatkeysAndBarcodesJob for BulkAction #{bulk_action_id}")
      update_druid_count(count: update_pids.count)
      update_pids.each_with_index do |current_druid, i|
        change_set = ItemChangeSet.new do |change|
          change.catkey = catkeys[i] if catkeys
          change.barcode = barcodes[i] if barcodes
        end
        update_catkey_and_barcode(current_druid, change_set, log) if change_set.changed?
      end
      log.puts("#{Time.current} Finished SetCatkeysAndBarcodesJob for BulkAction #{bulk_action_id}")
    end
  end

  protected

  def params_from(params)
    catkeys = dig_from_params_if_option_set(params, :catkeys)
    barcodes = dig_from_params_if_option_set(params, :barcodes)
    [pids, catkeys, barcodes]
  end

  private

  def update_catkey_and_barcode(current_druid, change_set, log)
    log.puts("#{Time.current} Beginning SetCatkeysAndBarcodesJob for #{current_druid}")
    cocina_object = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina_object)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    log_update(change_set, log)

    begin
      state_service = StateService.new(current_druid, version: cocina_object.version)
      open_new_version(cocina_object.externalIdentifier, cocina_object.version, version_message(change_set)) unless state_service.allows_modification?
      ItemChangeSetPersister.update(cocina_object, change_set)

      bulk_action.increment(:druid_count_success).save
      log.puts("#{Time.current} Catkey/barcode added/updated/removed successfully")
    rescue StandardError => e
      log.puts("#{Time.current} Catkey/barcode failed #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
      nil
    end
  end

  def dig_from_params_if_option_set(params, key)
    # This will preserve the blank lines as nils, which indicate that a catkey/barcode should be removed.
    params.dig(:set_catkeys_and_barcodes, key).split("\n").map(&:strip).map(&:presence) if params.dig(:set_catkeys_and_barcodes, "use_#{key}_option".to_sym) == '1'
  end

  # rubocop:disable Style/GuardClause
  def log_update(change_set, log)
    if change_set.catkey_changed?
      if change_set.catkey
        log.puts("#{Time.current} Adding catkey of #{change_set.catkey}")
      else
        log.puts("#{Time.current} Removing catkey")
      end
    end
    if change_set.barcode_changed?
      if change_set.barcode
        log.puts("#{Time.current} Adding barcode of #{change_set.barcode}")
      else
        log.puts("#{Time.current} Removing barcode")
      end
    end
  end
  # rubocop:enable Style/GuardClause

  def version_message(change_set)
    msgs = []
    if change_set.catkey_changed?
      msgs << if change_set.catkey
                "Catkey updated to #{change_set.catkey}."
              else
                'Catkey removed.'
              end
    end
    if change_set.barcode_changed?
      msgs << if change_set.barcode
                "Barcode updated to #{change_set.barcode}."
              else
                'Barcode removed.'
              end
    end
    msgs.join(' ')
  end
end
