# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvUploadValidator do
  let(:catalog_record_id_header) { CatalogRecordId.label.downcase.tr(" ", "_") }
  let(:csv) { "Druid,#{catalog_record_id_header},Barcode\ndruid:bb396kf5077,13157971,\ndruid:bb631ry3167,13965062,\n" }
  let(:headers) { ["Druid", catalog_record_id_header] }
  let(:validator) { described_class.new(csv:, headers:) }

  # TODO: This test is disabled temporarily during the FOLIO Cutover - ils_cutover_in_progress
  it "is valid", pending: "Folio cutover" do
    expect(validator).to be_valid
  end

  # TODO: This test is disabled temporarily during the FOLIO Cutover - ils_cutover_in_progress
  it "returns empty errors", pending: "Folio cutover" do
    expect(validator.errors).to be_empty
  end

  context "when ILS cutover flag is enabled" do
    around do |spec|
      original_value = Settings.ils_cutover_in_progress
      Settings.ils_cutover_in_progress = true
      spec.run
      Settings.ils_cutover_in_progress = original_value
    end

    context "when CSV contains catalog record ID values" do
      it "is not valid" do
        expect(validator).not_to be_valid
      end

      it "returns errors" do
        expect(validator.errors).to eq(["rows may not contain catalog record IDs during the ILS cutover"])
      end
    end

    context "when CSV lacks catalog record ID values" do
      let(:csv) { "Druid,#{catalog_record_id_header},Barcode\ndruid:bb396kf5077,,\ndruid:bb631ry3167,,\n" }

      it "is valid" do
        expect(validator).to be_valid
      end

      it "returns empty errors" do
        expect(validator.errors).to be_empty
      end
    end
  end

  context "when not all headers exist" do
    let(:headers) { ["xDruid", catalog_record_id_header] }

    it "is not valid" do
      expect(validator).not_to be_valid
    end

    # TODO: This test is disabled temporarily during the FOLIO Cutover - ils_cutover_in_progress
    it "returns errors", pending: "Folio cutover" do
      expect(validator.errors).to eq(["missing headers: xDruid."])
    end
  end
end
