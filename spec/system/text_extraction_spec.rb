# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Text Extractions', :js do
  let(:current_user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:cocina_model) { build(:dro_with_metadata, id: druid, version: 2, type: object_type) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, reindex: true) }
  let(:version_service) { instance_double(VersionService, open?: true) }

  before do
    allow(Repository).to receive(:find).with(druid).and_return(cocina_model)
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when item is a document' do
    before { allow(Settings.features).to receive(:ocr_workflow).and_return(true) }

    let(:object_type) { 'https://cocina.sul.stanford.edu/models/document' }

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
  end

  context 'when item is media' do
    let(:object_type) { 'https://cocina.sul.stanford.edu/models/media' }

    before { allow(Settings.features).to receive(:speech_to_text_workflow).and_return(true) }

    describe '#new' do
      it 'shows text extraction form' do
        visit "/items/#{druid}/text_extraction/new"

        expect(page).to have_css 'h3', text: 'Text extraction'
        expect(page).to have_content 'Avoid auto-generating caption/transcript files for media that do not contain any speech or lyrics'
      end
    end
  end
end
