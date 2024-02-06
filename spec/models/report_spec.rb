# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Report do
  # A helper method so this test does not couple to implementation details such
  # as knowing what order the report fields are in.
  def report_field_index(field_name)
    described_class::REPORT_FIELDS.index { |field| field[:field] == field_name }
  end

  let(:user) { instance_double(User, admin?: true) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")
    solr_conn.commit
  end

  describe '#to_csv' do
    let(:csv) do
      described_class
        .new(current_user: user)
        .to_csv # Returns an enumerator for more performant streaming of CSV results.
        .to_a   # Iterate through the enumerator.
        .join   # Coerce to string for parsing convenience.
    end

    it 'generates data in valid CSV format' do
      expect { CSV.parse(csv) }.not_to raise_error
    end

    it 'generates many rows of data' do
      rows = CSV.parse(csv)
      expect(rows).to be_a(Array)
      expect(rows.length).to be > 1 # at least headers + data
      expect(rows[report_field_index(:druid)].length).to eq(described_class::REPORT_FIELDS.size) # default headers
    end

    it 'forces double quotes for all fields' do
      expect(csv[report_field_index(:druid)]).to eq('"')
    end

    context 'when a field has double quotes' do
      before do
        solr_conn.add(id: 'druid:hj185xx2222',
                      display_title_ss: 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
        solr_conn.commit
      end

      it 'handles a title with double quotes in it' do
        row = CSV.parse(csv).find { |row| row[report_field_index(:druid)] == 'hj185xx2222' }
        expect(row[report_field_index(:title)]).to eq('Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
      end
    end

    context 'with multivalued fields' do
      before do
        solr_conn.add(id: 'druid:xb482ww9999',
                      tag_ssim: ['Project : Argo Demo', 'Registered By : mbklein'])
        solr_conn.commit
      end

      it 'handles a multivalued fields' do
        row = CSV.parse(csv).find { |row| row[report_field_index(:druid)] == 'xb482ww9999' }
        expect(row[report_field_index(:tag_ssim)].split(';').length).to eq(2)
      end
    end
  end

  describe 'REPORT_FIELDS' do
    subject(:report_fields) { described_class::REPORT_FIELDS }

    it 'has report fields' do
      expect(report_fields).to(be_all { |f| f[:field].is_a? Symbol }) # all :field keys are symbols
    end

    it 'has all the mandatory, default report fields' do
      [
        :druid,
        :purl,
        :citation,
        :source_id_ssi,
        SolrDocument::FIELD_APO_TITLE,
        :processing_status_text_ssi,
        :published_earliest_dttsi,
        :file_count,
        :shelved_file_count,
        :resource_count,
        :preserved_size,
        :preserved_size_human,
        :dissertation_id
      ].each do |k|
        expect(report_fields).to(be_any { |f| f[:field] == k })
      end
    end

    it 'has all the mandatory, non-default report fields' do
      [
        :title,
        SolrDocument::FIELD_APO_ID,
        SolrDocument::FIELD_COLLECTION_ID,
        SolrDocument::FIELD_COLLECTION_TITLE,
        :project_tag_ssim,
        :registered_by_tag_ssim,
        :registered_earliest_dttsi,
        :tag_ssim,
        :objectType_ssim,
        :content_type_ssim,
        CatalogRecordId.index_field,
        :barcode_id_ssim,
        :accessioned_earliest_dttsi,
        SolrDocument::FIELD_WORKFLOW_ERRORS.to_sym
      ].each do |k|
        expect(report_fields).to(be_any { |f| f[:field] == k })
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
                      obj_label_tesim: 'State Banking Commission Annual Reports')
        solr_conn.add(id: 'druid:mb062dy1188',
                      obj_label_tesim: 'maxims found in the leading English and American reports and elementary works')
        solr_conn.commit
      end

      it 'returns unqualified druids by default' do
        expect(report).to eq %w[fg464dn8891 mb062dy1188]
      end
    end

    it 'returns druids and source ids' do
      doc = { id: 'druid:qq613vj0238', source_id_ssi: 'sul:36105011952764' }
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
