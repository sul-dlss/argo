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
    druid_column = 'druid'
    update_druid_count(count: csv.size)
    with_bulk_action_log do |log|
      log.puts("CSV filename: #{params[:csv_filename]}")
      return unless check_druid_column(csv:, druid_column:, log:, bulk_action:)

      csv.each.with_index(2) do |csv_row, row_num|
        druid = csv_row.fetch(druid_column)
        DescriptionImportRowJob.perform_later(
          csv_row: csv_row.to_h,
          headers: csv_row.headers.excluding('source_id', 'druid'),
          row_num:,
          bulk_action:,
          groups:
        )
      end
    end
  end
end
