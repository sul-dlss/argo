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
end
