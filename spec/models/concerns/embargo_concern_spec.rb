# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EmbargoConcern do
  let(:document) { SolrDocument.new(document_attributes) }

  context 'when it is embargoed' do
    let(:document_attributes) do
      {
        SolrDocument::FIELD_EMBARGO_STATUS => ['embargoed'],
        SolrDocument::FIELD_EMBARGO_RELEASE_DATE => ['24/02/2259']
      }
    end

    it 'returns embargo status' do
      expect(document).to be_embargoed
      expect(document.embargo_status).to eq 'embargoed'
      expect(document.embargo_release_date).to eq '24/02/2259'
    end
  end

  describe 'when it is not embargoed' do
    let(:document_attributes) { {} }

    context 'with no field' do
      it 'returns nil' do
        expect(document).not_to be_embargoed
        expect(document.embargo_status).to be_nil
        expect(document.embargo_release_date).to be_nil
      end
    end

    context 'with empty field' do
      let(:document_attributes) do
        {
          SolrDocument::FIELD_EMBARGO_STATUS => nil,
          SolrDocument::FIELD_EMBARGO_RELEASE_DATE => nil
        }
      end

      it 'returns nil' do
        expect(document).not_to be_embargoed
        expect(document.embargo_status).to be_nil
        expect(document.embargo_release_date).to be_nil
      end
    end
  end
end
