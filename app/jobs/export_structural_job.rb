# frozen_string_literal: true

##
# A job that exports structural metadata to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] params additional parameters that an Argo job may need
class ExportStructuralJob < BulkActionJob
  def export_file
    @export_file ||= CSV.open(csv_download_path, 'w', write_headers: true, headers: StructureSerializer::HEADERS)
  end

  def csv_download_path
    File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename)
  end

  class ExportStructuralJobItem < BulkActionJobItem
    def perform
      return failure!(message: 'No structural metadata to export') if no_structural?

      StructureSerializer.new(druid, cocina_object.structural).rows do |row|
        export_file << row
      end
      success!(message: 'Exported structural metadata')
    end

    def no_structural?
      !cocina_object.dro? || Array(cocina_object.structural&.contains).empty?
    end
  end
end
