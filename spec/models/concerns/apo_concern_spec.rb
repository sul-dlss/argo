require 'spec_helper'

describe ApoConcern do
  let(:document) { SolrDocument.new(document_attributes) }
  describe '#apo' do
    context 'with data' do
      let(:document_attributes) { { SolrDocument::FIELD_APO_ID => ['info:fedora/druid:abc'], SolrDocument::FIELD_APO_TITLE => ['My title'] } }
      it 'should have an APO' do
        expect(document.apo_id).to eq('info:fedora/druid:abc')
        expect(document.apo_pid).to eq('druid:abc')
        expect(document.apo_title).to eq('My title')
      end
    end

    context 'with Uber-y data' do
      let(:document_attributes) { { :id => SolrDocument::UBER_APO_ID, SolrDocument::FIELD_TITLE => 'My title' } }
      it 'should handle an Uber-APO' do
        expect(document.apo_id).to eq(SolrDocument::UBER_APO_ID)
        expect(document.apo_pid).to eq(SolrDocument::UBER_APO_ID)
        expect(document.apo_title).to eq('My title')
      end
    end

    context 'with Hydrus Uber-y data' do
      let(:document_attributes) { { :id => SolrDocument::HYDRUS_UBER_APO_ID, SolrDocument::FIELD_TITLE => 'My title' } }
      it 'should handle an Uber-APO' do
        expect(document.apo_id).to eq(SolrDocument::HYDRUS_UBER_APO_ID)
        expect(document.apo_pid).to eq(SolrDocument::HYDRUS_UBER_APO_ID)
        expect(document.apo_title).to eq('My title')
      end
    end

    context 'without data' do
      let(:document_attributes) { {} }
      it 'should handle missing APO' do
        expect(document.apo_id).to be_nil
        expect(document.apo_pid).to be_nil
        expect(document.apo_title).to be_nil
      end
    end
  end
end
