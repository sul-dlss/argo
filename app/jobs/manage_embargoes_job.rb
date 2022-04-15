# frozen_string_literal: true

##
# Job to update/add embargoes to objects
class ManageEmbargoesJob < GenericJob
  include Dry::Monads[:result]

  ##
  # A job that allows a user to provide a spreadsheet for managing embargoes.
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file CSV string
  def perform(bulk_action_id, params)
    super

    csv = CSV.parse(params[:csv_file], headers: true)
    with_csv_items(csv, name: 'Embargo') do |cocina_object, csv_row, success, failure|
      return failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      open_version_if_needed(cocina_object)
      update_embargo(cocina_object, csv_row)
        .either(
          ->(_val) { success.call('Embargo updated') },
          ->(error) { failure.call(error) }
        )
    end
  end

  private

  def open_version_if_needed(cocina_object)
    state_service = StateService.new(cocina_object)
    msg = 'Manage embargo'
    open_new_version(cocina_object.externalIdentifier, cocina_object.version, msg) unless state_service.allows_modification?
  end

  def update_embargo(cocina_object, csv_row)
    validate_required_field(csv_row).bind do
      parse_date(csv_row).bind do |embargo_release_date|
        build_form(cocina_object, build_changes(csv_row, embargo_release_date)).bind do |form|
          Success(form.save)
        end
      end
    end
  end

  def validate_required_field(csv_row)
    return Failure('Missing required value for "release_date"') unless csv_row['release_date']

    Success()
  end

  def parse_date(csv_row)
    Success(DateTime.parse(csv_row['release_date']))
  rescue Date::Error
    Failure("#{csv_row['release_date']} is not a valid date")
  end

  def build_changes(csv_row, embargo_release_date)
    {
      release_date: embargo_release_date,
      view_access: csv_row['view'],
      download_access: csv_row['download'],
      access_location: csv_row['location']
    }
  end

  def build_form(cocina_object, changes)
    form = EmbargoForm.new(cocina_object)
    if form.validate(changes)
      Success(form)
    else
      Failure(form.errors.full_messages.join(','))
    end
  end
end
