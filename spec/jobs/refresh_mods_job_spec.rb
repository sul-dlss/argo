# frozen_string_literal: true

require "rails_helper"

RSpec.describe RefreshModsJob do
  let(:druids) { ["druid:bb111cc2222", "druid:cc111dd2222"] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:catalog_record_ids) do
    ["123"]
  end

  # NOTE: the `catkeys` arg in the cocina-models factories is currently the only
  #       possibility for catalog record IDs, and those map to Symphony catalog
  #       links. The next release (after 0.89.0) should contain a change
  #       allowing both the `catkeys` arg and the `folio_instance_hrids` arg
  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0], catkeys: catalog_record_ids)
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1], catkeys: catalog_record_ids)
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
        expect(logger).to have_received(:puts).with(/Did not update metadata because it doesn't have a Catkey for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/Did not update metadata because it doesn't have a Catkey for druid:cc111dd2222/)

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
