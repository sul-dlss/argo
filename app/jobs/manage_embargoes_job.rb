# frozen_string_literal: true

##
# Job to update/add embargoes to objects
class ManageEmbargoesJob < GenericJob
  ##
  # A job that allows a user to provide a spreadsheet for managing embargoes.
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file CSV string
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log|
      update_pids, embargo_release_dates, rights = params_from_csv(params)
      update_druid_count(count: update_pids.count)
      update_pids.each_with_index do |current_druid, i|
        update_embargo(current_druid, embargo_release_dates[i], rights[i], log) unless current_druid.nil?
      end
    end
  end

  private

  def params_from_csv(params)
    druids = []
    release_dates = []
    rights = []
    CSV.parse(params[:csv_file], headers: true).each do |row|
      druids << row['Druid']
      release_dates << row['Release_date']
      rights << row['Rights']
    end
    [druids, release_dates, rights]
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def update_embargo(current_druid, embargo_release_date_param, rights_param, log)
    log.puts("#{Time.current} Beginning ManageEmbargoesJob for #{current_druid}")

    begin
      embargo_release_date = embargo_release_date_param.present? ? DateTime.parse(embargo_release_date_param) : nil
    rescue Date::Error
      log.puts("#{Time.current} #{embargo_release_date_param} is not a valid date")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    cocina_object = Dor::Services::Client.object(current_druid).find

    unless ability.can?(:manage_item, cocina_object)
      log.puts("#{Time.current} Not authorized for #{current_druid}")
      bulk_action.increment(:druid_count_fail).save
      return
    end

    msg = "Setting embargo to #{rights_param} to be released on #{embargo_release_date_param}."
    log.puts("#{Time.current} #{msg}")

    begin
      state_service = StateService.new(current_druid, version: cocina_object.version)
      open_new_version(cocina_object.externalIdentifier, cocina_object.version, msg) unless state_service.allows_modification?

      changes = {}
      changes[:embargo_release_date] = embargo_release_date if embargo_release_date
      changes[:embargo_access] = rights_param if rights_param
      unless changes.empty?
        change_set = ItemChangeSet.new(cocina_object)
        if change_set.validate(changes) && change_set.save
          bulk_action.increment(:druid_count_success).save
          log.puts("#{Time.current} Embargo set successfully")
        else
          log.puts("#{Time.current} #{rights_param} is not a valid right")
          bulk_action.increment(:druid_count_fail).save
        end
      end
    rescue StandardError => e
      log.puts("#{Time.current} Embargo failed #{e.class} #{e.message}")
      bulk_action.increment(:druid_count_fail).save
      nil
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
