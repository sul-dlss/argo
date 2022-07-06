# frozen_string_literal: true

# Export a spreadsheet of descriptive metadata
class DescriptiveMetadataExportJob < GenericJob
  def perform(bulk_action_id, _params)
    super

    with_bulk_action_log do |log_buffer|
      log_buffer.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count

      # NOTE: This could potentially consume a lot of memory, because we don't know which columns a record has ahead of time,
      #  so we have to load all the records into memory first.
      descriptions = druids.each_with_object({}) do |druid, out|
        item = Repository.find(druid)
        if item.is_a?(NilModel)
          log_buffer.puts("#{Time.current} #{self.class}: Skipping description for #{druid} since not found (bulk_action.id=#{bulk_action_id})")
          bulk_action.increment(:druid_count_fail).save
        else
          description = DescriptionExport.export(source_id: item.identification.sourceId, description: item.description)
          out[druid] = description
          bulk_action.increment(:druid_count_success).save
        end
      end

      grouped_descriptions = DescriptionsGrouper.group(descriptions:)
      ordered_headers = DescriptionHeaders.create(headers: grouped_descriptions.values.flat_map(&:keys).uniq)

      log_buffer.puts("#{Time.current} #{self.class}: Writing to file")

      CSV.open(csv_download_path, 'w', write_headers: true, headers: %w[druid] + ordered_headers) do |csv|
        grouped_descriptions.each do |druid, description|
          csv << ([druid] + description.values_at(*ordered_headers))
        end
      end

      log_buffer.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def csv_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.descriptive_metadata_export_job.csv_filename)
  end
end
