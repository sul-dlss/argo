# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Report, type: :model do
  let(:user) { instance_double(User, is_admin?: true) }

  context 'csv' do
    before do
      @csv = described_class.new(
        current_user: user
      ).to_csv
    end

    it 'generates data in valid CSV format' do
      expect { CSV.parse(@csv) }.not_to raise_error
    end

    it 'generates many rows of data' do
      rows = CSV.parse(@csv)
      expect(rows.is_a?(Array)).to be_truthy
      expect(rows.length).to be > 1    # at least headers + data
      expect(rows[0].length).to eq(25) # default headers
    end

    it 'forces double quotes for all fields' do
      expect(@csv[0]).to eq('"')
    end

    it 'handles a title with double quotes in it' do
      row = CSV.parse(@csv).find { |row| row[0] == 'hj185vb7593' }
      expect(row[2]).to eq('Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953') # 2 == title field
    end

    it 'handles a multivalued fields' do
      row = CSV.parse(@csv).find { |row| row[0] == 'xb482bw3979' }
      expect(row[12].split('; ').length).to eq(2) # 12 == tag field
    end
  end

  describe 'blacklight config' do
    let(:config) { subject.instance_variable_get(:@blacklight_config) }
    it 'has all the facets available in the catalog controller' do
      expect(config.facet_fields.keys).to eq CatalogController.blacklight_config.facet_fields.keys
    end
    it 'has report fields' do
      expect(config.report_fields.length).to eq(25)
      expect(config.report_fields.all? { |f| f[:field].is_a? Symbol }).to be_truthy # all :field keys are symbols
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
        :preserved_size
      ].each do |k|
        expect(config.report_fields.any? { |f| f[:field] == k }).to be_truthy
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
        expect(config.report_fields.any? { |f| f[:field] == k }).to be_truthy
      end
    end
  end
  describe '#pids' do
    it 'returns unqualified druids by default' do
      expect(described_class.new(
        { q: 'report' }, %w(druid),
        current_user: user
      ).pids).to eq(%w(fg464dn8891 pb873ty1662 qq613vj0238))
    end
    it 'returns druids and source ids' do
      expect(described_class.new(
        { q: 'report' }, %w(druid source_id_ssim),
        current_user: user
      ).pids(source_id: true)).to include "qq613vj0238\tsul:36105011952764"
    end
    it 'returns druids and tags' do
      expect(described_class.new(
        { q: 'report' }, %w(druid tag_ssim),
        current_user: user
      ).pids(tags: true)).to include "fg464dn8891\tRegistered By : llam813\t Remediated By : 4.6.6.2"
    end
  end
end
