require 'spec_helper'

RSpec.describe EmbargoConcern do
  let(:document) { SolrDocument.new(document_attributes) }
  describe '#embargo_release_date' do
    let(:single_date) { ['2012-04-05T01:00:04.148Z'] }
    let(:document_attributes) do
      { SolrDocument::FIELD_EMBARGO_RELEASE_DATE => single_date }
    end
    it 'returns date' do
      expect(document.embargo_release_date).to match_array(single_date)
    end
  end
  describe '#embargo_status' do
    context 'when present' do
      let(:document_attributes) do
        { SolrDocument::FIELD_EMBARGO_STATUS => 'embargoed' }
      end
      it 'returns status' do
        expect(document.embargo_status).to eq 'embargoed'
      end
    end
    context 'when not present' do
      let(:document_attributes) { {} }
      it 'returns nil' do
        expect(document.embargo_status).to be_nil
      end
    end
  end
end
