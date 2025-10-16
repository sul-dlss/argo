# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshModsJob do
  subject(:perform) do
    described_class.perform_now(bulk_action.id,
                                druids:,
                                groups:,
                                user:)
  end

  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }
  let(:catalog_record_ids) { ['a123'] }
  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0], folio_instance_hrids: catalog_record_ids)
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1], folio_instance_hrids: catalog_record_ids)
  end
  let(:object_client1) do
    instance_double(Dor::Services::Client::Object, find: cocina1, refresh_descriptive_metadata_from_ils: true)
  end
  let(:object_client2) do
    instance_double(Dor::Services::Client::Object, find: cocina2, refresh_descriptive_metadata_from_ils: true)
  end
  let(:log) { instance_double(File, puts: nil, close: true) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'without catalog_record_id' do
      let(:catalog_record_ids) { [] }

      before { perform }

      it 'logs errors' do
        expect(log).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
        expect(log).to have_received(:puts).with(/Does not have a Folio Instance HRID for druid:bb111cc2222/)
        expect(log).to have_received(:puts).with(/Does not have a Folio Instance HRID for druid:cc111dd2222/)

        expect(object_client1).not_to have_received(:refresh_descriptive_metadata_from_ils)
        expect(object_client2).not_to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end

    context 'with catalog_record_id' do
      before do
        allow(VersionService).to receive(:open?).and_return(true)
      end

      context 'when the version is open' do
        before { perform }

        it 'refreshes' do
          expect(log).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
          expect(log).to have_received(:puts).with(/Successfully updated metadata for druid:bb111cc2222/)
          expect(log).to have_received(:puts).with(/Successfully updated metadata for druid:cc111dd2222/)

          expect(object_client1).to have_received(:refresh_descriptive_metadata_from_ils)
          expect(object_client2).to have_received(:refresh_descriptive_metadata_from_ils)
        end
      end

      context 'when the version is not open' do
        before do
          allow(VersionService).to receive_messages(open?: false, openable?: true)
          allow(VersionService).to receive(:open).with(a_hash_including(druid: druids[0])).and_return(cocina1.new(version: 2))
          allow(VersionService).to receive(:open).with(a_hash_including(druid: druids[1])).and_return(cocina2.new(version: 2))
        end

        it 'opens a version and refreshes' do
          perform

          expect(log).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
          expect(log).to have_received(:puts).with(/Successfully updated metadata for druid:bb111cc2222/)
          expect(log).to have_received(:puts).with(/Successfully updated metadata for druid:cc111dd2222/)

          expect(VersionService).to have_received(:open).exactly(2).times
          expect(object_client1).to have_received(:refresh_descriptive_metadata_from_ils)
          expect(object_client2).to have_received(:refresh_descriptive_metadata_from_ils)
        end
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    before { perform }

    it 'does not refresh' do
      expect(log).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
      expect(log).to have_received(:puts).with(/Not authorized to update for druid:cc111dd2222/)
      expect(log).to have_received(:puts).with(/Not authorized to update for druid:cc111dd2222/)
      expect(object_client1).not_to have_received(:refresh_descriptive_metadata_from_ils)
      expect(object_client2).not_to have_received(:refresh_descriptive_metadata_from_ils)
    end
  end
end
