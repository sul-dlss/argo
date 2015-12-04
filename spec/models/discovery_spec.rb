require 'spec_helper'

describe Discovery, :type => :model do
  context 'csv' do
    before :each do
      @csv = subject.to_csv
    end
    it 'should generate data in valid CSV format' do
      expect { CSV.parse(@csv) }.not_to raise_error
    end
    it 'should generate many rows of data' do
      rows = CSV.parse(@csv)
      expect(rows.is_a?(Array)).to be_truthy
      expect(rows.length).to be > 1   # at least headers + data
      expect(rows[0].length).to eq(15) # default headers
    end
    it 'should force double quotes for all fields' do
      expect(@csv[0]).to eq('"')
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
  end
end
