# frozen_string_literal: true

##
# A job that exports catalog_links to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] _params additional parameters that an Argo job may need
class ExportCatalogLinksJob < BulkActionJob
  HEADERS = %w[druid folio_instance_hrid refresh part_label sort_key barcode].freeze

  def export_file
    @export_file ||= CSV.open(csv_download_path, 'w', write_headers: true, headers: HEADERS)
  end

  class ExportCatalogLinksJobItem < BulkActionJobItem
    def perform
      export_file << [druid, *export_catalog_links]
      success!(message: 'Exporting FOLIO instance HRIDs and barcodes')
    end

    private

    def export_catalog_links
      object_client = Dor::Services::Client.object(druid)
      identification = object_client.find_lite.identification
      link = identification.catalogLinks.find { |catalog_link| catalog_link.catalog == 'folio' }

      [link&.catalogRecordId, link&.refresh, link&.partLabel, link&.sortKey, identification.barcode]
    end
  end

  def csv_download_path
    File.join(bulk_action.output_directory, Settings.export_catalog_links_job.csv_filename)
  end
end
