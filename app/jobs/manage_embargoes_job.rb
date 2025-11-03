# frozen_string_literal: true

##
# Job to update/add embargoes to objects
class ManageEmbargoesJob < BulkActionCsvJob
  class ManageEmbargoesJobItem < BulkActionCsvJobItem
    def perform
      return unless check_update_ability?

      return unless check_release_date?

      open_new_version_if_needed!(description: 'Created or updated embargo')

      return failure!(message: embargo_form.errors.full_messages.join(',')) unless embargo_form.validate(changes)

      embargo_form.save
      close_version_if_needed!

      success!(message: 'Embargo updated')
    end

    def check_release_date?
      if row['release_date'].blank?
        failure!(message: 'Missing required value for "release_date"')
        return false
      end

      release_date

      true
    rescue Date::Error
      failure!(message: "#{row['release_date']} is not a valid date")

      false
    end

    def release_date
      @release_date ||= DateTime.parse(row['release_date'])
    end

    def embargo_form
      @embargo_form ||= EmbargoForm.new(cocina_object)
    end

    def changes
      {
        release_date:,
        view_access: row['view'],
        download_access: row['download'],
        access_location: row['location']
      }
    end
  end
end
