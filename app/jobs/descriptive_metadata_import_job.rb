# frozen_string_literal: true

class DescriptiveMetadataImportJob < GenericJob
  include Dry::Monads[:result]
  queue_as :default

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
    csv = CSV.parse(params[:csv_file], headers: true)
    with_csv_items(csv, name: 'Import descriptive metadata') do |cocina_object, csv_row, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      DescriptionImport.import(csv_row:)
                       .bind { |description| validate_changed(cocina_object, description) }
                       .bind { |description| open_version(cocina_object, description) }
                       .bind { |description, new_cocina_object| CocinaValidator.validate_and_save(new_cocina_object, description:) }
                       .either(
                         ->(_updated) { success.call('Successfully updated') },
                         ->(messages) { failure.call(messages.to_sentence) }
                       )
    end
  end

  private

  def validate_changed(cocina_object, description)
    return Failure('Description unchanged') if cocina_object.description == description

    Success(description)
  end

  def open_version(cocina_object, description)
    cocina_object = open_new_version_if_needed(cocina_object, 'Descriptive metadata upload')

    Success([description, cocina_object])
  rescue RuntimeError => e
    Failure([e.message])
  end
end
