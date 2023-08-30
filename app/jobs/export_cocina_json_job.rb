# frozen_string_literal: true

##
# Job to export Cocina JSON
class ExportCocinaJsonJob < GenericJob
  ##
  # A job that exports gzipped line-oriented JSON for one or more Cocina objects
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  def perform(bulk_action_id, params)
    super

    File.open(json_download_path, "w") do |jsonl_file|
      with_items(params[:druids], name: "Export Cocina JSON") do |cocina_object, success, failure|
        jsonl_file << "#{cocina_object.to_json}\n"
        success.call("Exported full Cocina JSON")
      end
    end
    gzip_file
  end

  private

  def json_download_path
    FileUtils.mkdir_p(bulk_action.output_directory)
    File.join(bulk_action.output_directory, Settings.export_cocina_json_job.jsonl_filename)
  end

  def gzip_download_path
    File.join(bulk_action.output_directory, Settings.export_cocina_json_job.gzip_filename)
  end

  def gzip_file
    gzip = ActiveSupport::Gzip.compress(File.read(json_download_path))
    File.write(gzip_download_path, gzip, mode: "wb")
    FileUtils.rm_f(json_download_path)
  end
end
