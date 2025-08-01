# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CsvUploadNormalizer do
  describe '#read' do
    let(:csv) { described_class.read(filepath, remove_columns_without_headers: true, remove_preamble_rows: true) }

    let(:expected_csv) { "Druid,Catkey,Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }

    context 'with xls file' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.xls').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with xlsx file' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.xlsx').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with ods file' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.ods').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with bogus file extension' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.bogus').to_s }

      it 'raises an exception' do
        expect { csv }.to raise_error(RuntimeError, /Unsupported upload file type/)
      end
    end

    context 'with plain-old CSV' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode.csv').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with UTF-8 CSV' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_utf8.csv').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with CSV with invalid bytes' do
      let(:filepath) { file_fixture('invalid_bulk_upload_nonutf8.csv').to_s }

      it 'raises an exception' do
        expect { csv }.to raise_error(CSV::MalformedCSVError)
      end
    end

    context 'with columns without headers' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_extra_columns.csv').to_s }

      it 'removes the columns' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with preamble' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_preamble.csv').to_s }

      it 'removes the columns' do
        expect(csv).to eq(expected_csv)
      end
    end

    context 'with whitespace around the druid' do
      let(:filepath) { file_fixture('catalog_record_id_and_barcode_with_whitespace.csv').to_s }

      it 'reads the CSV' do
        expect(csv).to eq(expected_csv)
      end
    end
  end
end
