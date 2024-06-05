# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TextExtractionJob do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:document) do
    build(:dro_with_metadata, id: druids[0], type: 'https://cocina.sul.stanford.edu/models/document')
  end
  let(:map) do
    build(:dro_with_metadata, id: druids[1], type: 'https://cocina.sul.stanford.edu/models/map')
  end

  let(:document_client) { instance_double(Dor::Services::Client::Object, find: document, version: 1) }
  let(:map_client) { instance_double(Dor::Services::Client::Object, find: map, version: 1) }
  let(:languages) { ['English'] }
  let(:text_extraction_document) { instance_double(TextExtraction, start: true, possible?: true, wf_name: 'ocrWF') }
  let(:text_extraction_map) { instance_double(TextExtraction, start: false, possible?: false) }
  let(:ability) { instance_double(Ability, can?: true) }

  let(:params) do
    {
      druids:,
      text_extraction_languages: languages,
      user:
    }
  end

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(TextExtraction).to receive(:new).with(document, languages:).and_return(text_extraction_document)
    allow(TextExtraction).to receive(:new).with(map, languages:).and_return(text_extraction_map)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(document_client)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(map_client)
  end

  context 'when objects are openable' do
    before do
      allow(VersionService).to receive(:openable?).with(druid: druids[0]).and_return(true)
      allow(VersionService).to receive(:openable?).with(druid: druids[1]).and_return(true)
    end

    context 'when objects do not have active text extraction workflows already' do
      describe '#perform' do
        it 'starts text extraction for only the document (skips map)' do
          described_class.perform_now(bulk_action.id, params)
          expect(text_extraction_document).to have_received(:start)
          expect(text_extraction_map).not_to have_received(:start)
        end
      end
    end

    context 'when objects have active text extraction workflows already' do
      before do
        allow(WorkflowService).to receive(:workflow_active?).with(druid: document.externalIdentifier, version: document.version, wf_name: 'ocrWF').and_return(true)
        allow(WorkflowService).to receive(:workflow_active?).with(druid: map.externalIdentifier, version: map.version, wf_name: 'ocrWF').and_return(true)
      end

      describe '#perform' do
        it 'does not start text extraction for either object' do
          described_class.perform_now(bulk_action.id, params)
          expect(text_extraction_document).not_to have_received(:start)
          expect(text_extraction_map).not_to have_received(:start)
        end
      end
    end
  end

  context 'when objects are not openable' do
    before do
      allow(VersionService).to receive(:openable?).with(druid: druids[0]).and_return(false)
      allow(VersionService).to receive(:openable?).with(druid: druids[1]).and_return(false)
    end

    describe '#perform' do
      it 'does not start text extraction for either object' do
        described_class.perform_now(bulk_action.id, params)
        expect(text_extraction_document).not_to have_received(:start)
        expect(text_extraction_map).not_to have_received(:start)
      end
    end
  end

  context 'when not authored to update objects' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'does not update either object' do
      described_class.perform_now(bulk_action.id, params)
      expect(text_extraction_document).not_to have_received(:start)
      expect(text_extraction_map).not_to have_received(:start)
    end
  end
end
