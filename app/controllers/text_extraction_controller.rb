# frozen_string_literal: true

class TextExtractionController < ApplicationController
  def new; end

  def create
    languages = params[:text_extraction_languages] || []
    cocina_object = Repository.find(params[:item_id])
    context = { runOCR: true, manuallyCorrectedOCR: false, ocrLanguages: languages }
    wf_name = 'ocrWF'

    # check the workflow is present and active (not archived)
    return redirect_to solr_document_path(cocina_object.externalIdentifier), flash: { error: "#{wf_name} already exists!" } if helpers.workflow_active?(wf_name, cocina_object.externalIdentifier, cocina_object.version)

    WorkflowClientFactory.build.create_workflow_by_name(cocina_object.externalIdentifier,
                                                        wf_name,
                                                        context:,
                                                        version: cocina_object.version)

    # Force a Solr update before redirection.
    Dor::Services::Client.object(cocina_object.externalIdentifier).reindex

    msg = "Added #{wf_name}"
    redirect_to solr_document_path(cocina_object.externalIdentifier), notice: msg
  end
end
