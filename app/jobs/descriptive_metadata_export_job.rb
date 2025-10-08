# frozen_string_literal: true

# Export a spreadsheet of descriptive metadata
class DescriptiveMetadataExportJob < BulkActionJob
  def perform_bulk_action
    grouped_descriptions = DescriptionsGrouper.group(descriptions:)
    ordered_headers = DescriptionHeaders.create(headers: grouped_descriptions.values.flat_map(&:keys).uniq)

    log('Writing to file')

    CSV.open(csv_download_path, 'w', write_headers: true, headers: %w[druid] + ordered_headers) do |csv|
      grouped_descriptions.each do |druid, description|
        csv << ([druid] + description.values_at(*ordered_headers))
      end
    end
  end

  private

  def descriptions
    # NOTE: This could potentially consume a lot of memory, because we don't know which columns a record has ahead of time,
    #  so we have to load all the records into memory first.
    @descriptions ||= druids.each_with_object({}) do |druid, out|
      item = Repository.find(druid)
      description = DescriptionExport.export(source_id: item.identification.sourceId, description: item.description)
      out[druid] = description
      success!(druid: druid)
    rescue Dor::Services::Client::BadRequestError, URI::InvalidURIError
      failure!(druid: druid, message: 'Could not request object')
    rescue Dor::Services::Client::NotFoundResponse
      failure!(druid: druid, message: 'Could not find object')
    rescue Dor::Services::Client::UnexpectedResponse, NoMethodError => e
      failure!(druid: druid, message: "Failed #{e.class} #{e.message}")
    end
  end

  def csv_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.descriptive_metadata_export_job.csv_filename)
  end
end
