# frozen_string_literal: true

class ImportStructuralJob < GenericJob
  def perform(_batch_id, params)
    super

    csv = CSV.parse(params[:csv_file], headers: true)
    # Group the rows by druid
    grouped = csv.group_by { |row| row["druid"] }
    with_items(grouped.keys, name: "Import structural") do |cocina_item, success, failure|
      next failure.call("Not authorized") unless ability.can?(:update, cocina_item)

      state_service = StateService.new(cocina_item)
      next failure.call("Object cannot be modified in its current state.") unless state_service.allows_modification?

      druid = cocina_item.externalIdentifier
      result = StructureUpdater.from_csv(cocina_item, item_csv(csv.headers, grouped.fetch(druid)))

      if result.success?
        Repository.store(cocina_item.new(structural: result.value!))
        success.call("Updated #{druid}")
      else
        failure.call("Unable to update #{druid}")
      end
    end
  end

  private

  # Create a CSV with the given rows and without the druid column
  def item_csv(headers, rows)
    CSV.generate do |table|
      table.add_row(headers - ["druid"])
      rows.map { |row| row.delete_if { |header, _| header == "druid" } }.each do |row|
        table.add_row(row)
      end
    end
  end
end
