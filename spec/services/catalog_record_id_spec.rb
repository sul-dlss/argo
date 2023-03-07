# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogRecordId do
  subject(:catalog_record_id) { described_class.new(model) }

  let(:model) do
    build(:dro)
      .new(
        identification: {
          catalogLinks: [
            {catalog: "previous symphony", refresh: false, catalogRecordId: "6671606"},
            {catalog: "previous symphony", refresh: false, catalogRecordId: "6671"},
            {catalog: "previous symphony", refresh: false, catalogRecordId: "1441"},
            {catalog: "folio", refresh: true, catalogRecordId: "a4114"},
            {catalog: "previous folio", refresh: false, catalogRecordId: "a1441"},
            {catalog: "symphony", refresh: true, catalogRecordId: "4114"}
          ],
          sourceId: "test:foobar"
        }
      )
  end

  describe "#serialize" do
    subject(:serialized) { catalog_record_id.serialize(record_ids, refresh:) }

    context "when resetting catalog record IDs" do
      let(:record_ids) { [] }
      let(:refresh) { nil }

      it { is_expected.to have_attributes(count: 6) }
    end
  end
end
