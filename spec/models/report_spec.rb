# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Report, type: :model do
  let(:user) { instance_double(User, admin?: true) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.delete_by_query("#{SolrDocument::FIELD_OBJECT_TYPE}:item")
    solr_conn.commit
  end

  context 'csv' do
    let(:csv) do
      described_class.new(
        current_user: user
      ).to_csv
    end

    it 'generates data in valid CSV format' do
      expect { CSV.parse(csv) }.not_to raise_error
    end

    it 'generates many rows of data' do
      rows = CSV.parse(csv)
      expect(rows).to be_a(Array)
      expect(rows.length).to be > 1    # at least headers + data
      expect(rows[0].length).to eq(26) # default headers
    end

    it 'forces double quotes for all fields' do
      expect(csv[0]).to eq('"')
    end

    context 'when a field has double quotes' do
      before do
        solr_conn.add(id: 'druid:hj185xx2222',
                      sw_display_title_tesim: 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953')
        solr_conn.commit
      end

      it 'handles a title with double quotes in it' do
        row = CSV.parse(csv).find { |row| row[0] == 'hj185xx2222' }
        expect(row[2]).to eq('Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953') # 2 == title field
      end
    end

    context 'with multivalued fields' do
      before do
        solr_conn.add(id: 'druid:xb482ww9999',
                      tag_ssim: ['Project : Argo Demo', 'Registered By : mbklein'])
        solr_conn.commit
      end

      it 'handles a multivalued fields' do
        row = CSV.parse(csv).find { |row| row[0] == 'xb482ww9999' }
        expect(row[12].split(';').length).to eq(2) # 12 == tag field
      end
    end
  end

  describe 'REPORT_FIELDS' do
    subject(:report_fields) { described_class::REPORT_FIELDS }

    it 'has report fields' do
      expect(report_fields.length).to eq(26)
      expect(report_fields).to be_all { |f| f[:field].is_a? Symbol } # all :field keys are symbols
    end

    it 'has all the mandatory, default report fields' do
      [
        :druid,
        :purl,
        :citation,
        :source_id_ssim,
        SolrDocument::FIELD_APO_TITLE,
        :status_ssi,
        :published_dttsim,
        :file_count,
        :shelved_file_count,
        :resource_count,
        :preserved_size,
        :dissertation_id
      ].each do |k|
        expect(report_fields).to be_any { |f| f[:field] == k }
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
        SolrDocument::FIELD_CATKEY_ID,
        :barcode_id_ssim,
        :accessioned_dttsim,
        :workflow_status_ssim
      ].each do |k|
        expect(report_fields).to be_any { |f| f[:field] == k }
      end
    end
  end

  describe 'blacklight config' do
    let(:config) { subject.instance_variable_get(:@blacklight_config) }

    it 'has all the facets available in the catalog controller' do
      expect(config.facet_fields.keys).to eq CatalogController.blacklight_config.facet_fields.keys
    end
  end

  describe '#pids' do
    context 'with no attributes' do
      subject(:report) do
        described_class.new({ q: 'report' }, %w[druid], current_user: user).pids
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
      doc = SolrDocument.new(id: 'druid:qq613vj0238', source_id_ssim: 'sul:36105011952764')
      service = instance_double(Blacklight::SearchService)
      allow(Blacklight::SearchService).to receive(:new).and_return(service)
      allow(service).to receive(:search_results).and_return(
        [{ 'response' => { 'numFound' => '1' } }, [doc]],
        [{ 'response' => { 'numFound' => '1' } }, [doc]],
        [{ 'response' => { 'numFound' => '1' } }, []]
      )

      expect(described_class.new(
        { q: 'report' }, %w[druid source_id_ssim],
        current_user: user
      ).pids(source_id: true)).to include "qq613vj0238\tsul:36105011952764"
    end

    context 'with tags: true' do
      subject(:report) do
        described_class.new({ q: 'report' }, %w[druid tag_ssim], current_user: user).pids(tags: true)
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
