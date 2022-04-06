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

    update_druids, embargo_release_dates, rights = params_from_csv(params)
    with_items(update_druids, name: 'Embargo') do |cocina_object, success, failure, index|
      update_embargo(cocina_object, embargo_release_dates[index], rights[index], success, failure)
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
  def update_embargo(cocina_object, embargo_release_date_param, rights_param, success, failure)
    begin
      embargo_release_date = embargo_release_date_param.present? ? DateTime.parse(embargo_release_date_param) : nil
    rescue Date::Error
      return failure.call("#{embargo_release_date_param} is not a valid date")
    end

    return failure.call('Not authorized') unless ability.can?(:manage_item, cocina_object)

    state_service = StateService.new(cocina_object)
    msg = "Setting embargo to #{rights_param} to be released on #{embargo_release_date_param}."
    open_new_version(cocina_object.externalIdentifier, cocina_object.version, msg) unless state_service.allows_modification?

    changes = {}
    changes[:embargo_release_date] = embargo_release_date if embargo_release_date
    changes[:embargo_access] = rights_param if rights_param
    return success.call('no changes') if changes.empty?

    change_set = ItemChangeSet.new(cocina_object)
    if change_set.validate(changes) && change_set.save
      success.call("Embargo set to #{rights_param} to be released on #{embargo_release_date_param}.")
    else
      failure.call("#{rights_param} is not a valid right")
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
