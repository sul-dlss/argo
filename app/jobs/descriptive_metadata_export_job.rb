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
      headers = Set.new
      descriptions = druids.each_with_object({}) do |druid, out|
        log_buffer.puts("#{Time.current} #{self.class}: Exporting description for #{druid} (bulk_action.id=#{bulk_action_id})")
        item = Dor::Services::Client.object(druid).find
        description = DescriptionExport.export(item.description)
        out[druid] = description
        headers.merge(description.keys)
        bulk_action.increment(:druid_count_success).save
      end

      log_buffer.puts("#{Time.current} #{self.class}: Writing to file")
      ordered_headers = headers.to_a # Set doesn't have an order, but array does
      CSV.open(csv_download_path, 'w', write_headers: true, headers: %w[druid] + ordered_headers) do |csv|
        descriptions.each do |druid, description|
          csv << ([druid] + ordered_headers.map { |header| description[header] })
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