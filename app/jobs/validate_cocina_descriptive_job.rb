# frozen_string_literal: true

class ValidateCocinaDescriptiveJob < GenericJob
  queue_as :default

  ##
  # A job that allows a user to verify that a spreadsheet for descriptive upload is valid
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file csv data to validate
  def perform(bulk_action_id, params)
    super

    csv = CSV.parse(params[:csv_file], headers: true)
    with_csv_items(csv, name: "Validate Cocina descriptive metadata") do |cocina_object, csv_row, success, failure|
      DescriptionImport.import(csv_row:)
        .bind { |description| CocinaValidator.validate(cocina_object, description:) }
        .either(
          ->(_validated) { success.call("Successfully validated") },
          ->(error) { failure.call(error) }
        )
    end
  end
end
