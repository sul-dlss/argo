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

  let(:document_client) { instance_double(Dor::Services::Client::Object, find: document) }
  let(:map_client) { instance_double(Dor::Services::Client::Object, find: map) }
  let(:languages) { ['English'] }
  let(:text_extraction_document) { instance_double(TextExtraction, start: true, possible?: true) }
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

  describe '#perform' do
    it 'starts text extraction for only the document' do
      described_class.perform_now(bulk_action.id, params)
      expect(text_extraction_document).to have_received(:start)
      expect(text_extraction_map).not_to have_received(:start)
    end
  end
end
