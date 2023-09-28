# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvUploadValidator do
  let(:catalog_record_id_header) { CatalogRecordId.label.downcase.tr(" ", "_") }
  let(:csv) { "Druid,#{catalog_record_id_header},Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }
  let(:headers) { ["Druid", catalog_record_id_header] }
  let(:validator) { described_class.new(csv:, headers:) }

  it "is valid" do
    expect(validator).to be_valid
  end

  it "returns empty errors" do
    expect(validator.errors).to be_empty
  end

  context "when not all headers exist" do
    let(:headers) { ["xDruid", catalog_record_id_header] }

    it "is not valid" do
      expect(validator).not_to be_valid
    end

    it "returns errors" do
      expect(validator.errors).to eq(["missing headers: xDruid."])
    end
  end
end
