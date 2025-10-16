# frozen_string_literal: true

##
# Job to export Cocina JSON
class ExportCocinaJsonJob < BulkActionJob
  def perform_bulk_action
    super

    gzip_file
  end

  def export_file
    @export_file ||= File.open(json_download_path, 'w')
  end

  class ExportCocinaJsonJobItem < BulkActionJobItem
    def perform
      export_file << "#{cocina_object.to_json}\n"
      success!(message: 'Exported full Cocina JSON')
    end
  end

  private

  def json_download_path
    File.join(bulk_action.output_directory, Settings.export_cocina_json_job.jsonl_filename)
  end

  def gzip_download_path
    File.join(bulk_action.output_directory, Settings.export_cocina_json_job.gzip_filename)
  end

  def gzip_file
    export_file.close
    gzip = ActiveSupport::Gzip.compress(File.read(json_download_path))
    File.write(gzip_download_path, gzip, mode: 'wb')
    FileUtils.rm_f(json_download_path)
  end
end
