# frozen_string_literal: true

##
# job to register a list of druids
class RegisterDruidsJob < BulkActionJob
  HEADERS = ['Druid', 'Barcode', CatalogRecordId.label, 'Source Id', 'Label'].freeze

  def perform_bulk_action
    convert_results.each.with_index do |convert_result, index|
      perform_item_class.new(druid: 'Unregistered', index:, job: self, convert_result:).perform
    rescue StandardError => e
      failure!(druid: 'Unregistered', message: "Failed #{e.class} #{e.message}", index:)
    end
  end

  def druid_count
    convert_results.length
  end

  def convert_results
    @convert_results ||= RegistrationCsvConverter.convert(csv_string: params[:csv_file], params:)
  end

  def export_file
    @export_file ||= CSV.open(report_filename, 'wb', write_headers: true, headers: HEADERS)
  end

  def report_filename
    File.join(bulk_action.output_directory, Settings.register_druids_job.csv_filename)
  end

  class RegisterDruidsJobItem < BulkActionJobItem
    def initialize(convert_result:, **args)
      @convert_result = convert_result
      super(**args)
    end

    attr_reader :convert_result

    def perform
      return failure!(message: convert_result.failure.message) if convert_result.failure?

      registration_result = RegistrationService.register(**convert_result.value!)

      return failure!(message: registration_result.failure.message) if registration_result.failure?

      # Set druid and cocina_object so that logging, etc. works as expected.
      @cocina_object = registration_result.value!
      @druid = cocina_object.externalIdentifier

      success!(message: 'Registration successful')
      export_file << row
    end

    def row
      [
        Druid.new(cocina_object).without_namespace,
        cocina_object.identification.barcode,
        cocina_object.identification.catalogLinks.first&.catalogRecordId,
        cocina_object.identification.sourceId,
        cocina_object.label
      ]
    end
  end
end
