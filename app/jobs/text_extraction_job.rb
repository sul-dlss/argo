# frozen_string_literal: true

##
# Job to start ocrWF for objects
class TextExtractionJob < GenericJob
  ##
  # A job that allows a user to specify a list of druids of objects to start the text extraction workflow for
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for because groups are not persisted with the user.
  # @option params [Array] :user the user
  def perform(bulk_action_id, params)
    super

    with_items(params[:druids], name: 'Start Text Extraction') do |cocina_object, success, failure|
      next failure.call('Not authorized') unless ability.can?(:update, cocina_object)

      text_extraction = TextExtraction.new(cocina_object, languages: params[:text_extraction_languages])

      next failure.call('Text extraction is not possible for this object') unless text_extraction.possible?

      text_extraction.start

      success.call('Text extraction successfully started')
    end
  end
end
