# frozen_string_literal: true

require 'zip'

# Download metadata as a zip of xml files.
class DescmetadataDownloadJob < BulkActionJob
  def export_file
    @export_file ||= ::Zip::File.open(zip_filename, Zip::File::CREATE)
  end

  class DescmetadataDownloadJobItem < BulkActionJobItem
    def perform
      return unless check_read_ability?

      desc_metadata = PurlFetcher::Client::Mods.create(cocina: cocina_object)
      zip_file.get_output_stream("#{druid}.xml") { |f| f.puts(desc_metadata) }

      success!

      # Commit every 250 to limit memory usage.
      zip_file.commit if (index % 250).zero?
    end

    def zip_file
      job.export_file
    end
  end

  # @return [String] A filename for the zip file.
  def zip_filename
    @zip_filename ||= File.join(bulk_action.output_directory, Settings.bulk_metadata.zip)
  end
end
