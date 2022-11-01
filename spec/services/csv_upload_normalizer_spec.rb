# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvUploadNormalizer do
  describe "#read" do
    let(:csv) { described_class.read(filepath) }

    let(:expected_csv) { "Druid,Catkey,Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }

    context "xls file" do
      let(:filepath) { file_fixture("catkey_and_barcode.xls").to_s }

      it "reads the CSV" do
        expect(csv).to eq(expected_csv)
      end
    end

    context "xlsx file" do
      let(:filepath) { file_fixture("catkey_and_barcode.xlsx").to_s }

      it "reads the CSV" do
        expect(csv).to eq(expected_csv)
      end
    end

    context "ods file" do
      let(:filepath) { file_fixture("catkey_and_barcode.ods").to_s }

      it "reads the CSV" do
        expect(csv).to eq(expected_csv)
      end
    end

    context "bogus file extension" do
      let(:filepath) { file_fixture("catkey_and_barcode.bogus").to_s }

      it "raises an exception" do
        expect { csv }.to raise_error(RuntimeError, /Unsupported upload file type/)
      end
    end

    context "plain-old CSV" do
      let(:filepath) { file_fixture("catkey_and_barcode.csv").to_s }

      it "reads the CSV" do
        expect(csv).to eq(expected_csv)
      end
    end

    context "UTF-8 CSV" do
      let(:filepath) { file_fixture("catkey_and_barcode_utf8.csv").to_s }

      it "reads the CSV" do
        expect(csv).to eq(expected_csv)
      end
    end

    context "CSV with invalid bytes" do
      let(:filepath) { file_fixture("invalid_bulk_upload_nonutf8.csv").to_s }

      it "raises an exception" do
        expect { csv }.to raise_error(CSV::MalformedCSVError)
      end
    end
  end
end
