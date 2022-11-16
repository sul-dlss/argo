# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidateCocinaDescriptiveJob do
  let(:bulk_action) { create(:bulk_action, action_type: described_class.to_s) }
  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222] }
  let(:item1) { build(:dro, id: druids[0]) }
  let(:item2) { build(:dro, id: druids[1]) }
  let(:logger) { instance_double(File, puts: nil) }

  before do
    allow(BulkJobLog).to receive(:open).and_yield(logger)
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Repository).to receive(:find).with(druids[0]).and_return(item1)
    allow(Repository).to receive(:find).with(druids[1]).and_return(item2)
  end

  describe "#perform" do
    context "with valid cocina metadata" do
      let(:csv_file) do
        [
          "druid,source_id,title1:value,purl",
          [item1.externalIdentifier, item1.identification.sourceId, "new title 1", "https://purl/bb111cc2222"].join(","),
          [item2.externalIdentifier, item2.identification.sourceId, "new title 2", "https://purl/cc111dd2222"].join(",")
        ].join("\n")
      end

      before do
        subject.perform(bulk_action.id, {csv_file:})
      end

      it "updates the descriptive metadata for each item" do
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(bulk_action.druid_count_fail).to eq 0
        expect(bulk_action.druid_count_success).to eq druids.length
      end
    end

    context "with a invalid cocina metadata" do
      let(:csv_file) do
        [
          "druid,source_id,title1.structuredValue1.type,purl",
          [item1.externalIdentifier, item1.identification.sourceId, "new title 1", "https://purl"].join(","),
          [item2.externalIdentifier, item2.identification.sourceId, "new title 2", "https://purl"].join(",")
        ].join("\n")
      end

      before do
        subject.perform(bulk_action.id, {csv_file:})
      end

      it "does not update the descriptive metadata for each item" do
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(bulk_action.druid_count_fail).to eq druids.length
        expect(bulk_action.druid_count_success).to eq 0
      end
    end
  end
end
