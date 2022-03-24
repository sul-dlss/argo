# frozen_string_literal: true

##
# A job that exports structural metadata to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] params additional parameters that an Argo job may need
class ExportStructuralJob < GenericJob
  def perform(bulk_action_id, params)
    super

    CSV.open(csv_download_path, 'w', headers: true) do |csv|
      csv << ['druid', *StructureSerializer::HEADERS]
      with_items(params[:druids], name: 'Export structural metadata') do |cocina_object, success, failure|
        rows_for_file = item_to_rows(cocina_object, success, failure)
        druid = cocina_object.externalIdentifier.delete_prefix('druid:')
        rows_for_file.each do |row|
          csv << [druid, *row]
        end
      end
    end
  end

  private

  # @return [Array<Array>] Returns an array of rows for the object
  def item_to_rows(item, success, failure)
    result = []
    if !item.dro? || Array(item.structural&.contains).empty?
      failure.call('No structural metadata to export')
      return []
    end

    StructureSerializer.new(item.structural).rows do |row|
      result << row
    end
    success.call('Exported structural metadata')
    result
  rescue StandardError => e
    failure.call("Unexpected error exporting structural metadata: #{e.message}")
    Honeybadger.notify(e)
    result
  end

  def csv_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.export_structural_job.csv_filename)
  end
end
