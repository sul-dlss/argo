# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrackSheet do
  let(:druid) { 'xb482ww9999' }
  let(:instance) { described_class.new([druid]) }

  describe '#find_or_create_in_solr_by_id' do
    subject(:call) { instance.send(:find_or_create_in_solr_by_id, druid) }

    before do
      allow(SearchService).to receive(:query)
        .with("id:\"druid:#{druid}\"", rows: 1)
        .and_return(response)
    end

    let(:response) { { 'response' => { 'docs' => docs } } }
    let(:solr_doc) { { 'id' => "druid:#{druid}" } }

    context 'when the doc is found in solr' do
      let(:docs) { [solr_doc] }

      it 'returns the document' do
        expect(call).to eq SolrDocument.new(solr_doc)
      end
    end

    context 'when the doc is not in the search results' do
      before do
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)

        allow(SearchService).to receive(:query)
          .with("id:\"druid:#{druid}\"", rows: 1)
          .and_return(response, second_response)
      end

      let(:docs) { [] }
      let(:second_response) { { 'response' => { 'docs' => [solr_doc] } } }

      it 'reindexes and and tries again' do
        expect(call).to eq SolrDocument.new(solr_doc)
      end
    end
  end

  # NOTE: the test expectations here use "include" instead of "eq" because the tracking sheet adds a timestamp to the array, which can be flaky to test against
  describe '#doc_to_table' do
    subject(:call) { instance.send(:doc_to_table, solr_doc) }

    let(:title) { 'main title' }
    let(:solr_doc) do
      SolrDocument.new('id' => "druid:#{druid}", SolrDocument::FIELD_TITLE => title)
    end

    context 'when normal length title' do
      let(:title) { 'Correct title' } # the cocina title

      it 'builds the table for the solr doc with the correct title' do
        expect(call).to include(
          [
            'Object Label:',
            'Correct title' # we get the cocina title out!
          ]
        )
      end
    end

    context 'when really long title' do
      let(:title) { 'Stanford University. School of Engineeering Roger Howe Professorship: Stanford (Calif.), 2010-01-21.  And more stuff goes here' }

      it 'builds the table for the solr doc with a truncated title' do
        expect(call).to include(
          [
            'Object Label:',
            'Stanford University. School of Engineeering Roger Howe Professorship: Stanford (Calif.), 2010-01-21.  And m...'
          ]
        )
      end
    end

    context 'when no title' do
      let(:title) { '' }

      it 'builds the table for the solr doc with a blank title' do
        expect(call).to include(
          [
            'Object Label:',
            ''
          ]
        )
      end
    end

    context 'with a project name' do
      let(:solr_doc) do
        SolrDocument.new('id' => "druid:#{druid}",
                         SolrDocument::FIELD_TITLE => title,
                         SolrDocument::FIELD_PROJECT_TAG => 'School of Engineering photograph collection')
      end

      it 'adds the project name' do
        expect(call).to include(
          [
            'Project Name:',
            'School of Engineering photograph collection'
          ]
        )
      end
    end

    context 'with tags' do
      let(:solr_doc) do
        SolrDocument.new('id' => "druid:#{druid}",
                         SolrDocument::FIELD_TITLE => title,
                         SolrDocument::FIELD_TAGS => [
                           'Some : First : Tag',
                           'Some : Second : Tag',
                           'Project : Ignored'
                         ])
      end

      it 'adds the tags, ignoring a project tag' do
        expect(call).to include(
          [
            'Tags:',
            "Some : First : Tag\nSome : Second : Tag"
          ]
        )
      end
    end

    context 'with a catalog_record_id' do
      let(:solr_doc) do
        SolrDocument.new('id' => "druid:#{druid}",
                         SolrDocument::FIELD_TITLE => title,
                         SolrDocument::FIELD_FOLIO_INSTANCE_HRID => 'catkey123')
      end

      it 'adds the catkey' do
        expect(call).to include(
          [
            "#{CatalogRecordId.label}:",
            'catkey123'
          ]
        )
      end
    end

    context 'with a source_id' do
      let(:solr_doc) do
        SolrDocument.new('id' => "druid:#{druid}",
                         SolrDocument::FIELD_TITLE => title,
                         SolrDocument::FIELD_SOURCE_ID => 'source:123')
      end

      it 'adds the catalog_record_id' do
        expect(call).to include(
          [
            'Source ID:',
            'source:123'
          ]
        )
      end
    end

    context 'with a barcode' do
      let(:solr_doc) do
        SolrDocument.new('id' => "druid:#{druid}",
                         SolrDocument::FIELD_TITLE => title,
                         SolrDocument::FIELD_BARCODE_ID => 'barcode123')
      end

      it 'adds the catalog_record_id' do
        expect(call).to include(
          [
            'Barcode:',
            'barcode123'
          ]
        )
      end
    end
  end
end
