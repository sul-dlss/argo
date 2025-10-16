# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Report do
  # A helper method so this test does not couple to implementation details such
  # as knowing what order the report fields are in.
  def report_field_index(field_name)
    described_class::REPORT_FIELDS.index { |field| field[:field] == field_name.to_s }
  end

  let(:user) { instance_double(User, admin?: true) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")
    solr_conn.commit
  end

  describe '#stream_csv' do
    let(:csv) do
      stream = StringIO.new
      described_class.new(current_user: user).stream_csv(stream:)
      stream.string
    end

    it 'generates data in valid CSV format' do
      expect { CSV.parse(csv) }.not_to raise_error
    end

    it 'generates many rows of data' do
      rows = CSV.parse(csv)
      expect(rows).to be_a(Array)
      expect(rows.length).to be > 1 # at least headers + data
      expect(rows[report_field_index(SolrDocument::FIELD_BARE_DRUID)].length).to eq(described_class::REPORT_FIELDS.size) # default headers
    end

    it 'forces double quotes for all fields' do
      expect(csv[report_field_index(SolrDocument::FIELD_BARE_DRUID)]).to eq('"')
    end

    context 'when a field has double quotes' do
      before do
        solr_conn.add(
          id: 'druid:hj185xx2222',
          SolrDocument::FIELD_BARE_DRUID => 'hj185xx2222',
          display_title_ss: 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953'
        )
        solr_conn.commit
      end

      it 'handles a title with double quotes in it' do
        row = CSV.parse(csv).find { |row| row[report_field_index(SolrDocument::FIELD_BARE_DRUID)] == 'hj185xx2222' }

        expect(row[report_field_index(SolrDocument::FIELD_TITLE)]).to eq('Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
      end
    end

    context 'with multivalued fields' do
      before do
        solr_conn.add(id: 'druid:xb482ww9999',
                      SolrDocument::FIELD_BARE_DRUID => 'xb482ww9999',
                      tag_ssim: ['Project : Argo Demo', 'Registered By : mbklein'])
        solr_conn.commit
      end

      it 'handles a multivalued fields' do
        row = CSV.parse(csv).find { |row| row[report_field_index(SolrDocument::FIELD_BARE_DRUID)] == 'xb482ww9999' }
        expect(row[report_field_index(SolrDocument::FIELD_TAGS)].split(';').length).to eq(2)
      end
    end
  end

  describe 'blacklight config' do
    let(:config) { subject.instance_variable_get(:@blacklight_config) }

    it 'has all the facets available in the catalog controller' do
      expect(config.facet_fields.keys).to eq CatalogController.blacklight_config.facet_fields.keys
    end
  end

  describe '#druids' do
    context 'with no attributes' do
      subject(:report) do
        described_class.new({ q: 'report' }, current_user: user).druids
      end

      before do
        solr_conn.add(id: 'druid:fg464dn8891',
                      SolrDocument::FIELD_BARE_DRUID => 'fg464dn8891',
                      obj_label_tesim: 'State Banking Commission Annual Reports')
        solr_conn.add(id: 'druid:mb062dy1188',
                      SolrDocument::FIELD_BARE_DRUID => 'mb062dy1188',
                      obj_label_tesim: 'maxims found in the leading English and American reports and elementary works')
        solr_conn.commit
      end

      it 'returns unqualified druids by default' do
        expect(report).to eq %w[fg464dn8891 mb062dy1188]
      end
    end

    it 'returns druids and source ids' do
      doc = {
        'id' => 'druid:qq613vj0238',
        SolrDocument::FIELD_SOURCE_ID => 'sul:36105011952764',
        SolrDocument::FIELD_BARE_DRUID => 'qq613vj0238'
      }
      service = instance_double(Blacklight::SearchService)
      allow(Blacklight::SearchService).to receive(:new).and_return(service)
      allow(service).to receive(:search_results).and_return(
        Blacklight::Solr::Response.new({ 'response' => { 'numFound' => '1', 'docs' => [doc] } },
                                       {}, blacklight_config: CatalogController.blacklight_config),
        Blacklight::Solr::Response.new({ 'response' => { 'numFound' => '1', 'docs' => [doc] } },
                                       {}, blacklight_config: CatalogController.blacklight_config),
        Blacklight::Solr::Response.new({ 'response' => { 'numFound' => '1', 'docs' => [] } },
                                       {}, blacklight_config: CatalogController.blacklight_config)
      )

      expect(described_class.new(
        { q: 'report' },
        current_user: user
      ).druids(source_id: true)).to include "qq613vj0238\tsul:36105011952764"
    end

    context 'with tags: true' do
      subject(:report) do
        described_class.new({ q: 'report' }, current_user: user).druids(tags: true)
      end

      before do
        solr_conn.add(id: 'druid:fg464dn8891',
                      SolrDocument::FIELD_BARE_DRUID => 'fg464dn8891',
                      obj_label_tesim: 'State Banking Commission Annual Reports',
                      tag_ssim: ['Registered By : llam813', 'Remediated By : 4.6.6.2'])
        solr_conn.commit
      end

      it 'returns druids and tags' do
        expect(report).to include "fg464dn8891\tRegistered By : llam813\tRemediated By : 4.6.6.2"
      end
    end
  end
end
