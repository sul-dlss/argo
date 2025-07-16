# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TextExtractions', :js do
  let(:current_user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_model) { build(:dro_with_metadata, id: druid, version: 2, type: object_type) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, reindex: true) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow:, create_workflow_by_name: nil, lifecycle: Time.zone.now) }
  let(:workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
  let(:version_service) { instance_double(VersionService, open?: true) }

  before do
    allow(Repository).to receive(:find).with(druid).and_return(cocina_model)
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when item is a document' do
    let(:object_type) { 'https://cocina.sul.stanford.edu/models/document' }

    before { allow(Settings.features).to receive(:ocr_workflow).and_return(true) }

    describe '#create' do
      it 'adds ocrWF' do
        post "/items/#{druid}/text_extraction", params: { text_extraction_languages: ['English'] }
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'ocrWF', lane_id: 'low', context: { manuallyCorrectedOCR: false, ocrLanguages: ['English'] }, version: 2)
        expect(object_client).to have_received(:reindex)
        expect(response).to redirect_to(solr_document_path(druid))
      end
    end
  end

  context 'when item is media' do
    let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }

    before { allow(Settings.features).to receive(:speech_to_text_workflow).and_return(true) }

    describe '#create' do
      it 'adds speechToTextWF' do
        post "/items/#{druid}/text_extraction", params: {}
        expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'speechToTextWF', lane_id: 'low', context: {}, version: 2)
        expect(object_client).to have_received(:reindex)
        expect(response).to redirect_to(solr_document_path(druid))
      end
    end
  end
end
