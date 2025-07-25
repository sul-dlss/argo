# frozen_string_literal: true

# Start the correct text extraction workflow for a given object
class TextExtraction
  attr_reader :cocina_object, :languages, :already_opened

  # @param [Cocina::Models::DRO] cocina_object the object to start text extraction for
  # @param [Array<String>] languages the languages to extract text for, default to empty
  # @param [Boolean] already_opened whether the object has already been opened, default to true
  def initialize(cocina_object, languages: [], already_opened: true)
    @cocina_object = cocina_object
    @languages = languages
    @already_opened = already_opened
  end

  # start the correct text extraction workflow for the object if possible
  def start
    return false unless possible?

    version = cocina_object.version
    # if the object has already been opened, don't increment the version for the new workflow
    # this is to ensure the new workflow is started with the same version as the existing object
    # if the object is already open, they are the same; if not, ocrWF/speechToTextWF will open the object version, incrementing it
    version += 1 unless @already_opened
    Dor::Services::Client.object(cocina_object.externalIdentifier).workflow(wf_name).create(version:, lane_id: 'low', context:)
  end

  def possible?
    return false if cocina_object.blank?
    return false unless cocina_object.dro? && resource_type_mapping.key?(cocina_object.type)

    true
  end

  # the workflow to start
  def wf_name
    resource_type_mapping[cocina_object.type]
  end

  private

  # mapping of cocina resource types to workflow names
  def resource_type_mapping
    {}.tap do |mapping|
      if Settings.features.ocr_workflow
        mapping['https://cocina.sul.stanford.edu/models/book'] = 'ocrWF'
        mapping['https://cocina.sul.stanford.edu/models/document'] = 'ocrWF'
        mapping['https://cocina.sul.stanford.edu/models/image'] = 'ocrWF'
      end
      mapping['https://cocina.sul.stanford.edu/models/media'] = 'speechToTextWF' if Settings.features.speech_to_text_workflow
    end
  end

  # the workflow context to set
  def context
    case wf_name
    when 'ocrWF'
      { manuallyCorrectedOCR: false, ocrLanguages: languages }
    when 'speechToTextWF'
      {}
    end
  end
end
