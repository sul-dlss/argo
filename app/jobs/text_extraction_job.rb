# frozen_string_literal: true

##
# Job to start text extraction workflow for objects
class TextExtractionJob < BulkActionJob
  def languages
    params[:text_extraction_languages]
  end

  class TextExtractionJobItem < BulkActionJobItem
    delegate :languages, to: :job

    def perform
      return unless check_update_ability?

      return failure!(message: 'Text extraction is not possible for this object') unless text_extraction.possible?

      return failure!(message: 'Object is currently assembling') if version_service.assembling?

      text_extraction.start

      success!(message: "#{text_extraction.wf_name} successfully started")
    end

    private

    def version_service
      @version_service ||= VersionService.new(druid:)
    end

    def text_extraction
      @text_extraction ||= TextExtraction.new(cocina_object, languages:, already_opened: version_service.open?)
    end
  end
end
