# frozen_string_literal: true

##
# Job to update/add catkey/barcodes to objects
class SetCatkeysAndBarcodesJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids and a list of catkeys to be associated with these druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of
  # @option params [String] :catkeys list of catkeys to be associated 1:1 with druids in order
  # @option params [String] :use_catkeys_option option to update the catkeys
  # @option params [String] :barcodes list of barcodes to be associated 1:1 with druids in order
  # @option params [String] :use_barcodes_option option to update the barcodes
  def perform(bulk_action_id, params)
    super

    # Catkeys, barcodes are nil if not selected for use.
    update_druids, catkeys, barcodes = params_from(params)

    with_bulk_action_log do |log|
      update_druid_count(count: update_druids.count)
      update_druids.each_with_index do |current_druid, i|
        cocina_object = Repository.find(current_druid)
        args = {}
        args[:catkeys] = Array(catkeys[i]) if catkeys
        args[:barcode] = barcodes[i] if barcodes
        change_set = ItemChangeSet.new(cocina_object)
        change_set.validate(args)
        update_catkey_and_barcode(change_set, args, log) if change_set.changed?
      end
    end
  end

  protected

  def params_from(params)
    catkeys = catkeys_from_params(params)
    barcodes = barcodes_from_params(params)
    [druids, catkeys, barcodes]
  end

  private

  def update_catkey_and_barcode(change_set, args, log)
    cocina_object = change_set.model
    log.puts("#{Time.current} Beginning SetCatkeysAndBarcodesJob for #{cocina_object.externalIdentifier}")

    unless ability.can?(:update, cocina_object)
      log.puts("#{Time.current} Not authorized for #{cocina_object.externalIdentifier}")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    log_update(change_set, log)

    begin
      new_cocina_model = open_new_version_if_needed(cocina_object, version_message(change_set))
      new_change_set = ItemChangeSet.new(new_cocina_model)
      new_change_set.validate(args)
      new_change_set.save

      bulk_action.increment(:druid_count_success).save
      log.puts("#{Time.current} Catkey/barcode added/updated/removed successfully")
    rescue StandardError => e
      log.puts("#{Time.current} Catkey/barcode failed #{e.class} #{e.message}")
      Honeybadger.context(args:, druid: cocina_object.externalIdentifier)
      Honeybadger.notify(e)
      bulk_action.increment(:druid_count_fail).save
      nil
    end
  end

  def catkeys_from_params(params)
    return unless params['use_catkeys_option'] == '1'

    lines_for(params, :catkeys).map { |line| line.split(',') }
  end

  def barcodes_from_params(params)
    return unless params['use_barcodes_option'] == '1'

    lines_for(params, :barcodes).map(&:strip).map(&:presence)
  end

  # This will preserve the blank lines as nils, which indicate that a catkey/barcode should be removed.
  def lines_for(params, key)
    params.fetch(key).split("\n")
  end

  # rubocop:disable Style/GuardClause
  def log_update(change_set, log)
    if change_set.changed?(:catkeys)
      if change_set.catkeys.present?
        log.puts("#{Time.current} Adding catkey of #{change_set.catkeys.join(', ')}")
      else
        log.puts("#{Time.current} Removing catkey")
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
  # rubocop:enable Style/GuardClause

  def version_message(change_set)
    msgs = []
    if change_set.changed?(:catkeys)
      msgs << if change_set.catkeys.present?
                "Catkey updated to #{change_set.catkeys.join(', ')}."
              else
                'Catkey removed.'
              end
    end
    if change_set.changed?(:barcode)
      msgs << if change_set.barcode
                "Barcode updated to #{change_set.barcode}."
              else
                'Barcode removed.'
              end
    end
    msgs.join(' ')
  end
end
