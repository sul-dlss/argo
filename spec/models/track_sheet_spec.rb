# frozen_string_literal: true

require 'rails_helper'

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

    context 'when the doc is not in the search results' do
      before do
        allow(Argo::Indexer).to receive(:reindex_pid_remotely)

        allow(Dor::SearchService).to receive(:query)
          .with('id:"druid:xb482bw3979"', rows: 1)
          .and_return(response, second_response)
      end

      let(:docs) { [] }
      let(:second_response) { { 'response' => { 'docs' => [solr_doc] } } }

      it 'reindexes and and tries again' do
        expect(call).to eq solr_doc
      end
    end
  end
end
