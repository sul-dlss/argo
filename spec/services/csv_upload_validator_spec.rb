# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvUploadValidator do
  let(:csv) { "Druid,#{CatalogRecordId.csv_header},Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }
  let(:header_validators) do
    [
      CsvUploadValidator::RequiredHeaderValidator.new(headers:),
      CsvUploadValidator::OrRequiredDataValidator.new(headers: or_headers)
    ]
  end
  let(:headers) { %w[Druid Barcode] }
  let(:or_headers) { ['Label', CatalogRecordId.csv_header] }
  let(:validator) { described_class.new(csv:, header_validators:) }

  it 'is valid' do
    expect(validator).to be_valid
  end

  it 'returns empty errors' do
    expect(validator.errors).to be_empty
  end

  context 'when not all required headers exist' do
    let(:headers) { ['xDruid', CatalogRecordId.csv_header] }

    it 'is not valid' do
      expect(validator).not_to be_valid
    end

    it 'returns errors' do
      expect(validator.errors).to eq(['missing headers: xDruid.'])
    end
  end

  context 'when not all required OR headers exist' do
    let(:or_headers) { ['Label', "x#{CatalogRecordId.csv_header}"] }

    it 'is not valid' do
      expect(validator).not_to be_valid
    end

    it 'returns errors' do
      expect(validator.errors).to eq(['missing header. One of these must be provided: Label, xfolio_instance_hrid'])
    end
  end

  context 'when not all required OR data exist' do
    let(:csv) { "Druid,#{CatalogRecordId.csv_header},Barcode\ndruid:bb396kf5077,,\ndruid:bb631ry3167,13965062,\n" }

    it 'is not valid' do
      expect(validator).not_to be_valid
    end

    it 'returns errors' do
      expect(validator.errors).to eq(['missing data. For each row, one of these must be provided: Label, folio_instance_hrid'])
    end
  end
end
