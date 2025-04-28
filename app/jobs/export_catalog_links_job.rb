# frozen_string_literal: true

##
# A job that exports catalog_links to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] _params additional parameters that an Argo job may need
class ExportCatalogLinksJob < GenericJob
  def perform(bulk_action_id, _params)
    super

    with_bulk_action_log do |log_buffer|
      update_druid_count
      headers = %w[druid folio_instance_hrid refresh part_label sort_key barcode]
      CSV.open(csv_download_path, 'w', write_headers: true, headers: headers) do |csv|
        druids.each do |druid|
          log_buffer.puts("#{Time.current} #{self.class}: Exporting catalogLinks for #{druid} (bulk_action.id=#{bulk_action_id})")
          csv << [druid, *export_catalog_links(druid)]
          bulk_action.increment(:druid_count_success).save
        rescue StandardError => e
          log_buffer.puts("#{Time.current} #{self.class}: Unexpected error exporting catalogLinks for #{druid} (bulk_action.id=#{bulk_action.id}): #{e}")
          bulk_action.increment(:druid_count_fail).save
        end
      end
    end
  end

  private

  def export_catalog_links(druid)
    object_client = Dor::Services::Client.object(druid)
    identification = object_client.find_lite.identification
    link = identification.catalogLinks.find { |catalog_link| catalog_link.catalog == 'folio' }

    [link&.catalogRecordId, link&.refresh, link&.partLabel, link&.sortKey, identification.barcode]
  end

  def csv_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.export_catalog_links_job.csv_filename)
  end
end
