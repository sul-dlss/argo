# frozen_string_literal: true

class ImportStructuralJob < BulkActionJob
  def csv
    @csv ||= CSV.parse(params[:csv_file], headers: true)
  end

  def grouped_rows
    @grouped_rows ||= csv.group_by { |row| row['druid'] }
  end

  # druids are not passed in as a param, but derived from the CSV
  def druids
    @druids ||= grouped_rows.keys
  end

  class ImportStructuralJobItem < BulkActionJobItem
    delegate :csv, :grouped_rows, to: :job

    def perform
      return unless check_update_ability?

      open_new_version_if_needed!(description: 'Updated structural metadata')

      result = StructureUpdater.from_csv(cocina_object, item_csv)
      if result.success?
        Repository.store(cocina_object.new(structural: result.value!))
        close_version_if_needed!

        success!(message: "Updated #{druid}")
      else
        failure!(message: "Unable to update #{druid}")
      end
    end

    # Create a CSV with the given rows and without the druid column
    def item_csv
      CSV.generate do |table|
        table.add_row(csv.headers - ['druid'])
        rows.map { |row| row.delete_if { |header, _| header == 'druid' } }.each do |row|
          table.add_row(row)
        end
      end
    end

    def rows
      grouped_rows.fetch(druid)
    end
  end
end
