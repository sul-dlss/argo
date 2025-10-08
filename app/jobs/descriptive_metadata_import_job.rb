# frozen_string_literal: true

class DescriptiveMetadataImportJob < BulkActionCsvJob
  class DescriptiveMetadataImportJobItem < BulkActionCsvJobItem
    def perform
      return unless check_update_ability?

      import_result = DescriptionImport.import(csv_row: row)
      return failure!(message: import_result.failure.to_sentence) if import_result.failure?

      description = import_result.value!

      # this validates input data from spreadsheet before any updates are applied to provide error messages to the user
      validate_result = CocinaValidator.validate(cocina_object, description:)
      return failure!(message: "Validation failed (#{validate_result.failure})") if validate_result.failure?

      return failure!(message: 'Description unchanged') if cocina_object.description == description

      open_new_version_if_needed!(description: 'Descriptive metadata upload')

      @cocina_object = cocina_object.new(description:)
      Repository.store(cocina_object)

      close_version_if_needed!
      success!(message: 'Successfully updated')
    end
  end
end
