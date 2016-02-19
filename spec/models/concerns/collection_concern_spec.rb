require 'spec_helper'

describe CollectionConcern do
  let(:document) { SolrDocument.new(document_attributes) }

  describe '#collection' do
    context 'with data' do
      let(:document_attributes) { { SolrDocument::FIELD_COLLECTION_ID => ['druid:abc', 'druid:def'], SolrDocument::FIELD_COLLECTION_TITLE => ['Abc', 'Def'] } }
      it 'should have a Collections' do
        expect(document.collection_id).to eq('druid:abc')
        expect(document.collection_ids).to eq(['druid:abc', 'druid:def'])
        expect(document.collection_title).to eq('Abc')
        expect(document.collection_titles).to eq(['Abc', 'Def'])
      end
    end

    context 'without data' do
      let(:document_attributes) { {  } }
      it 'should handle no Collections' do
        expect(document.collection_id).to be_nil
        expect(document.collection_ids).to be_nil
        expect(document.collection_title).to be_nil
        expect(document.collection_titles).to be_nil
      end
    end
  end
end
