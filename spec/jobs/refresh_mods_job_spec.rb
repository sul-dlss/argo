# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RefreshModsJob, type: :job do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:catkeys) do
    ['123']
  end

  let(:cocina1) do
    Cocina::Models::Factories.build(:dro, id: druids[0], catkeys: catkeys)
  end
  let(:cocina2) do
    Cocina::Models::Factories.build(:dro, id: druids[1], catkeys: catkeys)
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, refresh_descriptive_metadata_from_ils: true) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, refresh_descriptive_metadata_from_ils: true) }
  let(:logger) { double('logger', puts: nil) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(BulkJobLog).to receive(:open).and_yield(logger)

    described_class.perform_now(bulk_action.id,
                                druids: druids,
                                groups: groups,
                                user: user)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'without catkey' do
      let(:catkeys) { [] }

      it 'logs errors' do
        expect(logger).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/Did not update metadata because it doesn't have a catkey for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/Did not update metadata because it doesn't have a catkey for druid:cc111dd2222/)

        expect(object_client1).not_to have_received(:refresh_descriptive_metadata_from_ils)
        expect(object_client2).not_to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end

    context 'with catkey' do
      it 'refreshes' do
        expect(logger).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
        expect(logger).to have_received(:puts).with(/Successfully updated metadata for druid:bb111cc2222/)
        expect(logger).to have_received(:puts).with(/Successfully updated metadata for druid:cc111dd2222/)

        expect(object_client1).to have_received(:refresh_descriptive_metadata_from_ils)
        expect(object_client2).to have_received(:refresh_descriptive_metadata_from_ils)
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not refresh' do
      expect(logger).to have_received(:puts).with(/Starting RefreshModsJob for BulkAction/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(object_client1).not_to have_received(:refresh_descriptive_metadata_from_ils)
      expect(object_client2).not_to have_received(:refresh_descriptive_metadata_from_ils)
    end
  end
end
