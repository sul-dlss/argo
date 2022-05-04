# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvUploadValidator do
  let(:validator) { described_class.new(csv:, headers:) }

  let(:csv) { "Druid,Catkey,Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }

  context 'when all headers exist' do
    let(:headers) { %w[Druid Catkey] }

    it 'is valid' do
      expect(validator.valid?).to be true
    end

    it 'returns empty errors' do
      expect(validator.errors).to be_empty
    end
  end

  context 'when not all headers exist' do
    let(:headers) { %w[xDruid Catkey] }

    it 'is not valid' do
      expect(validator.valid?).to be false
    end

    it 'returns errors' do
      expect(validator.errors).to eq ['Missing headers: xDruid']
    end
  end
end
