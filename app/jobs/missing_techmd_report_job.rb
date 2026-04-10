# frozen_string_literal: true

# A job that, given a list of druids, checks the technical metadata service for each object
# and generates a CSV report of those with files in Cocina and stored in preservation but
# with no technical metadata results.
class MissingTechmdReportJob < BulkActionJob
  HEADERS = %w[druid].freeze

  def perform_bulk_action
    return unless check_view_ability?

    super
  end

  def export_file
    @export_file ||= CSV.open(report_filename, 'w', write_headers: true, headers: HEADERS)
  end

  class MissingTechmdReportJobItem < BulkActionJobItem
    def perform
      return success! if preserved_cocina_files.empty?
      return success! if Preservation::Client.objects.checksum(druid:).empty?

      result = TechmdService.techmd_for(druid:)

      if result.failure?
        failure!(message: result.failure)
        return
      end

      export_file << [druid] if result.value!.empty?
      success!
    rescue Preservation::Client::NotFoundError
      success!
    end

    delegate :export_file, to: :job

    private

    def preserved_cocina_files
      return [] unless cocina_object.dro?

      Array(cocina_object.structural&.contains).flat_map do |resource|
        resource.structural.contains.select { |file| file.administrative.sdrPreserve }
      end
    end
  end

  private

  def report_filename
    File.join(bulk_action.output_directory, Settings.missing_techmd_report_job.csv_filename)
  end
end
