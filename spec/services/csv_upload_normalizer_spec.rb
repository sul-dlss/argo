# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvUploadNormalizer do
  describe '#read' do
    let(:csv) { described_class.read(filepath) }

    let(:expected_csv) { "Druid,Catkey,Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }

    context 'plain-old CSV' do
      let(:filepath) { file_fixture('catkey_and_barcode.csv').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'UTF-8 CSV' do
      let(:filepath) { file_fixture('catkey_and_barcode_utf8.csv').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end
  end
end
