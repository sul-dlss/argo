# frozen_string_literal: true

require "rails_helper"

RSpec.describe RefreshModsJob do
  let(:druids) { ["druid:bb111cc2222", "druid:cc111dd2222"] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:catalog_record_ids) do
    if Settings.enabled_features.folio
      ["a123"]
    else
      ["123"]
    end
  end

  let(:cocina1) do
    if Settings.enabled_features.folio
      build(:dro_with_metadata, id: druids[0], folio_instance_hrids: catalog_record_ids)
    else
      build(:dro_with_metadata, id: druids[0], catkeys: catalog_record_ids)
    end
  end
  let(:cocina2) do
    if Settings.enabled_features.folio
      build(:dro_with_metadata, id: druids[1], folio_instance_hrids: catalog_record_ids)
    else
      build(:dro_with_metadata, id: druids[1], catkeys: catalog_record_ids)
    end
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, refresh_descriptive_metadata_from_ils: true) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, refresh_descriptive_metadata_from_ils: true) }
  let(:logger) { double("logger", puts: nil) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(BulkJobLog).to receive(:open).and_yield(logger)

    described_class.perform_now(bulk_action.id,
      druids:,
      groups:,
      user:)
  end

  context "with manage ability" do
    let(:ability) { instance_double(Ability, can?: true) }

    context "without catalog_record_id" do
      let(:catalog_record_ids) { [] }

      it "logs errors" do
        expect(logger).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/Did not update metadata because it doesn't have a #{CatalogRecordId.label} for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/Did not update metadata because it doesn't have a #{CatalogRecordId.label} for druid:cc111dd2222/)

        expect(object_client1).not_to have_received(:refresh_descriptive_metadata_from_ils)
        expect(object_client2).not_to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end

    context "with catalog_record_id" do
      it "refreshes" do
        expect(logger).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/Successfully updated metadata for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/Successfully updated metadata for druid:cc111dd2222/)

        expect(object_client1).to have_received(:refresh_descriptive_metadata_from_ils)
        expect(object_client2).to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end
  end

  context "without manage ability" do
    let(:ability) { instance_double(Ability, can?: false) }

    it "does not refresh" do
      expect(logger).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(object_client1).not_to have_received(:refresh_descriptive_metadata_from_ils)
      expect(object_client2).not_to have_received(:refresh_descriptive_metadata_from_ils)
    end
  end
end
