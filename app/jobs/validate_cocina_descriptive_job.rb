# frozen_string_literal: true

class ValidateCocinaDescriptiveJob < BulkActionCsvJob
  class ValidateCocinaDescriptiveJobItem < BulkActionCsvJobItem
    def perform
      import_result = DescriptionImport.import(csv_row: row)
      return failure!(message: import_result.failure) if import_result.failure?

      description = import_result.value!
      validation_result = CocinaValidator.validate(cocina_object, description:)
      return failure!(message: validation_result.failure) if validation_result.failure?

      success!(message: 'Successfully validated')
    end
  end
end
