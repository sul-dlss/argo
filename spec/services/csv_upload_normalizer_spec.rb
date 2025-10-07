# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvUploadNormalizer do
  describe '#read' do
    let(:csv) { described_class.read(filepath.to_s) }
    let(:expected_csv) { "Druid,Catkey,Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }

    context 'with xls file' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.xls') }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with xlsx file' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.xlsx') }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with ods file' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.ods') }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with bogus file extension' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.bogus') }

      it 'raises an exception' do
        expect { csv }.to raise_error(RuntimeError, /Unsupported upload file type/)
      end
    end

    context 'with plain-old CSV' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.csv') }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with UTF-8 CSV' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_utf8.csv') }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with CSV with invalid bytes' do
      let(:filepath) { file_fixture('invalid_bulk_upload_nonutf8.csv') }

      it 'raises an exception' do
        expect { csv }.to raise_error(CSV::MalformedCSVError)
      end
    end

    context 'with columns without headers' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_extra_columns.csv') }

      it 'removes the columns' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with preamble' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_preamble.csv') }

      it 'removes the columns' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with whitespace in some fields including whitespace-only fields' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_with_whitespace.csv') }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with rows that are empty but for delimiters and whitespace' do
      let(:filepath) { file_fixture('null-descriptive-blank-end-rows.csv') }

      it 'reads the CSV and does not normalize the empty lines' do
        expect(csv).to eq(expected_csv)
      end
    end
  end
end
