# frozen_string_literal: true

##
# A job that exports tags to CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] _params additional parameters that an Argo job may need
class ExportTagsJob < BulkActionJob
  def export_file
    @export_file ||= CSV.open(csv_download_path, 'w')
  end

  def csv_download_path
    File.join(bulk_action.output_directory, Settings.export_tags_job.csv_filename)
  end

  class ExportTagsJobItem < BulkActionJobItem
    def perform
      export_file << [druid, *export_tags]
      success!(message: 'Exported tags')
    end

    private

    def export_tags
      Dor::Services::Client.object(druid).administrative_tags.list
    end
  end
end
