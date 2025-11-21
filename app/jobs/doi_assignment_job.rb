# frozen_string_literal: true

##
# Job to assign DOIs to objects
class DoiAssignmentJob < BulkActionJob
  class DoiAssignmentJobItem < BulkActionJobItem
    def perform
      return failure!(message: 'Not authorized to assign DOIs') unless ability.can?(:assign, :doi)

      return failure!(message: 'DOIs may only be assigned to items, not collections or APOs') unless cocina_object.dro?

      return failure!(message: "Errors in DataCite metadata: #{datacite_validator.errors.join(', ')}") unless datacite_validator.valid?

      open_new_version_if_needed!(description: 'Assigned DOI')

      Dor::Services::Client.object(druid).update(params: updated_cocina_object)

      close_version_if_needed!

      success!(message: 'Successfully assigned DOI')
    end

    private

    def datacite_validator
      @datacite_validator ||= Datacite::Validators::CocinaValidator.new(cocina_object:)
    end

    def updated_cocina_object
      cocina_object.new(
        identification: cocina_object.identification.new(
          doi: "#{Settings.datacite.prefix}/#{druid.delete_prefix('druid:')}"
        )
      )
    end
  end
end
