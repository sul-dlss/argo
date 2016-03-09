require 'spec_helper'

describe Report, :type => :model do
  context 'csv' do
    before :each do
      @csv = described_class.new(
        current_user: mock_user(is_admin?: true)
      ).to_csv
    end

    it 'should generate data in valid CSV format' do
      expect { CSV.parse(@csv) }.not_to raise_error
    end

    it 'should generate many rows of data' do
      rows = CSV.parse(@csv)
      expect(rows.is_a?(Array)).to be_truthy
      expect(rows.length).to be > 1    # at least headers + data
      expect(rows[0].length).to eq(25) # default headers
    end

    it 'should force double quotes for all fields' do
      expect(@csv[0]).to eq('"')
    end

    it 'should handle a title with double quotes in it' do
      row = CSV.parse(@csv).find { |row| row[0] == 'hj185vb7593' }
      expect(row[2]).to eq('Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953') # 2 == title field
    end

    it 'should handle a multivalued fields' do
      row = CSV.parse(@csv).find { |row| row[0] == 'xb482bw3979' }
      expect(row[12].split('; ').length).to eq(2) # 12 == tag field
    end
  end
  describe 'blacklight config' do
    let(:config) { subject.instance_variable_get(:@blacklight_config) }
    it 'should have the date facets' do
      keys = config.facet_fields.keys
      expect(keys).to include 'registered_date', SolrDocument::FIELD_REGISTERED_DATE.to_s
      expect(keys).to include 'accessioned_latest_date', SolrDocument::FIELD_LAST_ACCESSIONED_DATE.to_s
      expect(keys).to include 'published_latest_date', SolrDocument::FIELD_LAST_PUBLISHED_DATE.to_s
      expect(keys).to include 'submitted_latest_date', SolrDocument::FIELD_LAST_SUBMITTED_DATE.to_s
      expect(keys).to include 'deposited_date', SolrDocument::FIELD_LAST_DEPOSITED_DATE.to_s
      expect(keys).to include 'object_modified_date', SolrDocument::FIELD_LAST_MODIFIED_DATE.to_s
      expect(keys).to include 'version_opened_date', SolrDocument::FIELD_LAST_OPENED_DATE.to_s
      expect(keys).to include 'embargo_release_date', SolrDocument::FIELD_EMBARGO_RELEASE_DATE.to_s
    end
    it 'should have report fields' do
      expect(config.report_fields.length).to eq(25)
      expect(config.report_fields.all? { |f| f[:field].is_a? Symbol }).to be_truthy # all :field keys are symbols
    end
    it 'should have all the mandatory, default report fields' do
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
        expect(config.report_fields.any? { |f| f[:field] == k}).to be_truthy
      end
    end
    it 'should have all the mandatory, non-default report fields' do
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
        expect(config.report_fields.any? { |f| f[:field] == k}).to be_truthy
      end
    end
  end
end
