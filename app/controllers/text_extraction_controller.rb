# frozen_string_literal: true

class TextExtractionController < ApplicationController
  before_action :load_and_authorize_resource

  def new; end

  def create
    languages = params[:text_extraction_languages] || []

    text_extraction = TextExtraction.new(@cocina_object, languages:)

    return redirect_to solr_document_path(@cocina_object.externalIdentifier), flash: { error: 'Text extraction not possible for this object' } unless text_extraction.possible?

    wf_name = text_extraction.wf_name

    # check the workflow is present and active (not archived)
    return redirect_to solr_document_path(@cocina_object.externalIdentifier), flash: { error: "#{wf_name} already exists!" } if WorkflowService.workflow_active?(druid: @cocina_object.externalIdentifier, version: @cocina_object.version, wf_name:)

    text_extraction.start

    # Force a Solr update before redirection.
    Dor::Services::Client.object(@cocina_object.externalIdentifier).reindex

    redirect_to solr_document_path(@cocina_object.externalIdentifier), notice: "Started text extraction workflow (#{wf_name})"
  end

  private

  def load_and_authorize_resource
    @cocina_object = Repository.find(params[:item_id])
    authorize! :update, @cocina_object
  end
end
