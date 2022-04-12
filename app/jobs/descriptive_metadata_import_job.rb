# frozen_string_literal: true

class DescriptiveMetadataImportJob < GenericJob
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

      DescriptionImport.import(csv_row: csv_row).either(
        ->(description) { Repository.store(cocina_object.new(description: description)) && success.call('Successfully updated') },
        ->(error) { failure.call(error) }
      )
    end
  end
end
