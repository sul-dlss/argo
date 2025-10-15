# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvUploadValidator do
  let(:csv) { "Druid,#{CatalogRecordId.csv_header},Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }
  let(:required_headers) { %w[Druid Barcode] }
  let(:validator) { described_class.new(csv:, required_headers:) }

  before do
    validator.valid?
  end

  it 'is valid' do
    expect(validator).to be_valid
  end

  it 'returns empty errors' do
    expect(validator.errors).to be_empty
  end

  context 'when not all required headers exist' do
    let(:required_headers) { ['xDruid', CatalogRecordId.csv_header] }

    it 'is not valid' do
      expect(validator).not_to be_valid
    end

    it 'returns errors' do
      expect(validator.errors).to eq(['missing headers: xDruid.'])
    end
  end

  context 'when blank rows at end' do
    let(:required_headers) { %w[source_id] }
    let(:csv) do
      <<~CSV
        barcode,folio_instance_hrid,source_id,label
        ,,not:blank001,not blank
        ,,not:blank002,blank rows below this line
        ,,,,
        ,,,,
      CSV
    end

    it 'ignores the blank rows at the END' do
      expect(validator).to be_valid
    end
  end
end
