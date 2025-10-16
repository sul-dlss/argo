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
  # queue_as :default

  # ##
  # # A job that registers druids
  # # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # # @option [String] :register_druids CSV string
  # def perform(bulk_action_id, params)
  #   super

  #   results = RegistrationCsvConverter.convert(csv_string: params[:csv_file], params:)
  #   report_filename = generate_report_filename(bulk_action.output_directory)
  #   with_bulk_action_log do |log|
  #     update_druid_count(count: results.length)
  #     CSV.open(report_filename, 'wb') do |report|
  #       report << ['Druid', 'Barcode', CatalogRecordId.label, 'Source Id', 'Label']

  #       results.each do |parse_result|
  #         parse_result.either(->(value) { register(value, bulk_action:, log:, report:) },
  #                             ->(error) { log_error(error, bulk_action:, log:) })
  #       end
  #     end
  #   end
  # end

  # private

  # # @param [Array<Result>]
  # # @return [Array<Result>]
  # def register(value, bulk_action:, log:, report:)
  #   log.puts("#{Time.current} #{self.class}: Registering with #{value.inspect}")
  #   registration_result = RegistrationService.register(**value)
  #   registration_result.either(->(cocina_model) { log_success(cocina_model, bulk_action:, log:, report:) },
  #                              ->(error) { log_error(error, bulk_action:, log:) })
  # end

  # def log_success(model, bulk_action:, log:, report:)
  #   log.puts("#{Time.current} #{self.class}: Successfully registered #{model.externalIdentifier}")
  #   report << [Druid.new(model).without_namespace, model.identification.barcode,
  #              model.identification.catalogLinks.first&.catalogRecordId, model.identification.sourceId, model.label]
  #   bulk_action.increment(:druid_count_success).save
  # end

  # def log_error(error, bulk_action:, log:)
  #   log.puts("#{Time.current} #{self.class}: #{error.message}")
  #   bulk_action.increment!(:druid_count_fail)
  # end

  # ##
  # # Generate a filename for the job's csv report output file.
  # # @param  [String] output_dir Where to store the csv file.
  # # @return [String] A filename for the csv file.
  # def generate_report_filename(output_dir)
  #   FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
  #   File.join(output_dir, Settings.register_druids_job.csv_filename)
  # end
end
