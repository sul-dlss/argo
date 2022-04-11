# frozen_string_literal: true

require 'roo'

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
    # uploaded_file is the file provided by the user, it can be a CSV, ODS or Excel file (xls or xlsx)
    uploaded_file = params[:uploaded_file]

    raise 'Unsupported upload file type' unless %w[.csv .ods .xls .xlsx].include? File.extname(uploaded_file)

    spreadsheet = Roo::Spreadsheet.open(uploaded_file) # open the spreadsheet

    csv = CSV.parse(spreadsheet.to_csv, headers: true) # convert data to CSV and then parse by the CSV library as done in other parts of Argo
    with_csv_items(csv, name: 'Import descriptive metadata') do |cocina_object, csv_row, success, failure|
      next failure.call('Not authorized') unless ability.can?(:manage_item, cocina_object)

      DescriptionImport.import(csv_row: csv_row).either(
        ->(description) { Repository.store(cocina_object.new(description: description)) && success.call('Successfully updated') },
        ->(error) { failure.call(error) }
      )
    end
  end
end
