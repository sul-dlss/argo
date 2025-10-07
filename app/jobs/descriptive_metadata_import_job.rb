# frozen_string_literal: true

class DescriptiveMetadataImportJob < GenericJob
  include Dry::Monads[:result]

  queue_as :default

  ##
  # A job that allows a user to make descriptive updates from a CSV file
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file file
  # @option params [String] :csv_filename the name of the file
  def perform(bulk_action_id, params)
    super
    csv = CSV.parse(params[:csv_file], headers: true)
    with_csv_items(csv, name: 'Import descriptive metadata',
                        filename: params[:csv_filename]) do |cocina_object, csv_row, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      DescriptionImport.import(csv_row:)
                       .bind { |description| validate_input(cocina_object, description) }
                       .bind { |description| validate_changed(cocina_object, description) }
                       .bind { |description| open_version(cocina_object, description) }
                       .bind { |description, new_cocina_object| save(new_cocina_object, description) }
                       .bind { |new_cocina_object| close_version(new_cocina_object) }
                       .either(
                         ->(_updated) { success.call('Successfully updated') },
                         ->(messages) { failure.call(messages.to_sentence) }
                       )
    end
  end

  private

  # this validates input data from spreadsheet before any updates are applied to provide error messages to the user
  def validate_input(cocina_object, description)
    result = CocinaValidator.validate(cocina_object, description:)
    return Success(description) if result.success?

    Failure(["validation failed for #{cocina_object.externalIdentifier}: #{result.failure}"])
  end

  def validate_changed(cocina_object, description)
    return Failure(['Description unchanged']) if cocina_object.description == description

    Success(description)
  end

  def open_version(cocina_object, description)
    cocina_object = open_new_version_if_needed(cocina_object, 'Descriptive metadata upload')

    Success([description, cocina_object])
  rescue RuntimeError => e
    Failure([e.message])
  end

  def save(cocina_object, description)
    updated_object = cocina_object.new(description:)
    Repository.store(updated_object)
    Success(updated_object)
  rescue RuntimeError => e
    Failure(["save failed for #{cocina_object.externalIdentifier}: #{e.message}"])
  end

  def close_version(cocina_object)
    # Do not close the initial version of an object on a metadata update
    VersionService.close(druid: cocina_object.externalIdentifier) unless cocina_object.version == 1
    Success()
  rescue RuntimeError => e
    Failure([e.message])
  end
end
