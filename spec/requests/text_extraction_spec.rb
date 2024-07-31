# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TextExtractions', :js do
  let(:current_user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_model) { build(:dro_with_metadata, id: druid, version: 2, type: 'https://cocina.sul.stanford.edu/models/document') }

  before do
    allow(Repository).to receive(:find).with(druid).and_return(cocina_model)
    sign_in current_user, groups: ['sdr:administrator-role']
  end

  describe '#new' do
    it 'shows text extraction form with languages' do
      visit "/items/#{druid}/text_extraction/new"

      expect(page).to have_css 'h3', text: 'Text extraction'
      expect(page).to have_content 'Avoid auto-generating OCR files for PDF documents'
      expect(page).to have_css 'div', text: 'Content language'

      first('button[aria-label="toggle dropdown"]').click

      find('[data-text-extraction-label="Adyghe"]').click

      expect(page).to have_css 'div', text: 'Selected language(s)'
      expect(page.all('.selected-item-label').count).to eq 1

      find('[data-text-extraction-label="English"]').click
      expect(page.all('.selected-item-label').count).to eq 2
    end
  end

  describe '#create' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, reindex: true) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow:, create_workflow_by_name: nil, lifecycle: Time.zone.now) }
    let(:workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
    let(:version_service) { instance_double(VersionService, open?: true) }

    before do
      allow(VersionService).to receive(:new).and_return(version_service)
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'adds ocrWF' do
      post "/items/#{druid}/text_extraction", params: { text_extraction_languages: ['English'] }
      expect(workflow_client).to have_received(:create_workflow_by_name).with(druid, 'ocrWF', context: { runOCR: true, manuallyCorrectedOCR: false, ocrLanguages: ['English'] }, version: 2)
      expect(object_client).to have_received(:reindex)
      expect(response).to redirect_to(solr_document_path(druid))
    end
  end
end
