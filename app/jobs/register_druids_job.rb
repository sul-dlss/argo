# frozen_string_literal: true

##
# job to register a list of druids
class RegisterDruidsJob < GenericJob
  queue_as :default

  ##
  # A job that registers druids
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @option [String] :register_druids CSV string
  def perform(bulk_action_id, params)
    super

    results = RegistrationCsvConverter.convert(csv_string: params[:csv_file], params:)
    report_filename = generate_report_filename(bulk_action.output_directory)

    with_bulk_action_log do |log|
      update_druid_count(count: results.length)
      CSV.open(report_filename, 'wb') do |report|
        report << ['Druid', 'Source Id', 'Label']

        results.each do |parse_result|
          parse_result.either(->(value) { register(value, bulk_action:, log:, report:) },
                              ->(error) { log_error(error, bulk_action:, log:) })
        end
      end
    end
  end

  private

  # @param [Array<Result>]
  # @return [Array<Result>]
  def register(value, bulk_action:, log:, report:)
    log.puts("#{Time.current} #{self.class}: Registering with #{value.inspect}")
    registration_result = RegistrationService.register(**value)
    registration_result.either(->(cocina_model) { log_success(cocina_model, bulk_action:, log:, report:) },
                               ->(error) { log_error(error, bulk_action:, log:) })
  end

  def log_success(model, bulk_action:, log:, report:)
    log.puts("#{Time.current} #{self.class}: Successfully registered #{model.externalIdentifier}")
    report << [Druid.new(model).without_namespace, model.identification.sourceId, model.label]
    bulk_action.increment(:druid_count_success).save
  end

  def log_error(error, bulk_action:, log:)
    log.puts("#{Time.current} #{self.class}: #{error.message}")
    bulk_action.increment!(:druid_count_fail)
  end

  ##
  # Generate a filename for the job's csv report output file.
  # @param  [String] output_dir Where to store the csv file.
  # @return [String] A filename for the csv file.
  def generate_report_filename(output_dir)
    FileUtils.mkdir_p(output_dir) unless File.directory?(output_dir)
    File.join(output_dir, Settings.register_druids_job.csv_filename)
  end
end
