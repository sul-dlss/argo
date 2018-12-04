# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreservationSizeConcern do
  let(:document) { SolrDocument.new(document_attributes) }
  describe '#preservation_size' do
    context 'with data' do
      let(:document_attributes) do
        { SolrDocument::FIELD_PRESERVATION_SIZE => 123214 }
      end
      it 'returns size' do
        expect(document.preservation_size).to eq 123214
      end
    end
    context 'without data' do
      let(:document_attributes) { {} }
      it 'returns nil' do
        expect(document.preservation_size).to be_nil
      end
    end
  end
end
