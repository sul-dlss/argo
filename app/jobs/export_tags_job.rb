# frozen_string_literal: true

##
# A job that exports tags to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] _params additional parameters that an Argo job may need
class ExportTagsJob < GenericJob
  def perform(bulk_action_id, _params)
    super

    with_bulk_action_log do |log_buffer|
      update_druid_count

      CSV.open(csv_download_path, 'w') do |csv|
        druids.each do |druid|
          log_buffer.puts("#{Time.current} #{self.class}: Exporting tags for #{druid} (bulk_action.id=#{bulk_action_id})")
          csv << [druid, *export_tags(druid)]
          bulk_action.increment(:druid_count_success).save
        rescue StandardError => e
          log_buffer.puts("#{Time.current} #{self.class}: Unexpected error exporting tags for #{druid} (bulk_action.id=#{bulk_action.id}): #{e}")
          bulk_action.increment(:druid_count_fail).save
        end
      end
    end
  end

  private

  def export_tags(druid)
    Dor::Services::Client.object(druid).administrative_tags.list
  end

  def csv_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.export_tags_job.csv_filename)
  end
end
