# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TrackSheet do
  let(:druid) { 'xb482bw3979' }
  let(:instance) { described_class.new([druid]) }

  describe '#find_or_create_in_solr_by_id' do
    subject(:call) { instance.send(:find_or_create_in_solr_by_id, druid) }

    before do
      allow(Dor::SearchService).to receive(:query)
        .with('id:"druid:xb482bw3979"', rows: 1)
        .and_return(response)
    end

    let(:response) { { 'response' => { 'docs' => docs } } }
    let(:solr_doc) { instance_double(Hash) }

    context 'when the doc is found in solr' do
      let(:docs) { [solr_doc] }

      it 'returns the document' do
        expect(call).to eq solr_doc
      end
    end

    context 'when the doc is not in foo' do
      before do
        allow(Dor).to receive(:find).and_return(obj)
        allow(Dor::SearchService.solr).to receive(:add)
      end

      let(:docs) { [] }
      let(:obj) { instance_double(Dor::Item, to_solr: solr_doc) }

      it 'loads the document from Fedora and adds it to the index' do
        expect(call).to eq solr_doc
        expect(Dor::SearchService.solr).to have_received(:add).with(solr_doc)
      end
    end
  end
end
