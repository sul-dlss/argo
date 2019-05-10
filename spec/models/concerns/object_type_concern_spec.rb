# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectTypeConcern do
  let(:document) { SolrDocument.new(document_attributes) }

  describe '#object_type' do
    context 'when field present' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['item', 'other stuff'] }
      end

      it 'returns the first object type' do
        expect(document.object_type).to eq 'item'
      end
    end

    context 'when field not present' do
      let(:document_attributes) { {} }

      it 'returns nil' do
        expect(document.object_type).to be_nil
      end
    end
  end

  describe '#admin_policy?' do
    context 'when object type is an adminPolicy' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['adminPolicy'] }
      end

      it 'checks and returns true' do
        expect(document.admin_policy?).to be true
      end
    end

    context 'when object type is not an adminPolicy' do
      let(:document_attributes) do
        { SolrDocument::FIELD_OBJECT_TYPE => ['item'] }
      end

      it 'checks and returns false' do
        expect(document.admin_policy?).to be false
      end
    end

    context 'when object type is missing' do
      let(:document_attributes) { {} }

      it 'checks and returns false' do
        expect(document.admin_policy?).to be false
      end
    end
  end
end
