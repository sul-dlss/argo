# frozen_string_literal: true

##
# A job that exports structural metadata to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] _params additional parameters that an Argo job may need
class ExportStructuralJob < GenericJob
  def perform(bulk_action_id, _params)
    super

    with_bulk_action_log do |log_buffer|
      log_buffer.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")
      update_druid_count

      CSV.open(csv_download_path, 'w', headers: true) do |csv|
        csv << ['druid', *StructureSerializer::HEADERS]
        pids.each do |druid|
          rows_for_file = item_to_rows(druid, log_buffer)
          rows_for_file.each do |row|
            csv << [druid, *row]
          end
        end
      end

      log_buffer.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  # @return [Array<Array>] Returns an array of rows for the object
  def item_to_rows(druid, log_buffer)
    result = []
    log_buffer.puts("#{Time.current} #{self.class}: Loading #{druid}")
    item = Dor::Services::Client.object(druid).find
    if !item.dro? || item.structural.contains.empty?
      log_failure("Object #{druid} has no structural metadata to export", log_buffer)
      return []
    end

    log_buffer.puts("#{Time.current} #{self.class}: Exporting structural metadata for #{druid}")
    StructureSerializer.new(item.structural).rows do |row|
      result << row
    end
    bulk_action.increment(:druid_count_success).save
    result
  rescue StandardError => e
    log_buffer.puts("#{Time.current} #{self.class}: Unexpected error exporting structural metadata for #{druid}: #{e}")
    bulk_action.increment(:druid_count_fail).save
    result
  end

  def log_failure(message, log_buffer)
    log_buffer.puts("#{Time.current} #{self.class}: #{message}")
    bulk_action.increment(:druid_count_fail).save
  end

  def csv_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename)
  end
end
