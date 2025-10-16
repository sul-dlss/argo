# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyApoDefaultsJob do
  let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0])
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1])
  end

  let(:object_client1) do
    instance_double(Dor::Services::Client::Object, find: cocina1, apply_admin_policy_defaults: true)
  end
  let(:object_client2) do
    instance_double(Dor::Services::Client::Object, find: cocina2, apply_admin_policy_defaults: true)
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

    let(:perform) do
      described_class.perform_now(bulk_action.id,
                                  druids:,
                                  groups:,
                                  user:)
    end

    before do
      allow(VersionService).to receive(:open?).and_return(true)
    end

    context 'when the version is open' do
      before { perform }

      it 'refreshes' do
        expect(log).to have_received(:puts).with(/Starting ApplyApoDefaultsJob for BulkAction/)
        expect(log).to have_received(:puts).with(/Successfully applied defaults for druid:bb111cc2222/)
        expect(log).to have_received(:puts).with(/Successfully applied defaults for druid:cc111dd2222/)

        expect(object_client1).to have_received(:apply_admin_policy_defaults)
        expect(object_client2).to have_received(:apply_admin_policy_defaults)
      end
    end

    context 'when the version is not open' do
      let(:state_service) { instance_double(StateService, open?: false) }

      before do
        allow(VersionService).to receive_messages(open?: false, openable?: true)
        allow(VersionService).to receive(:open).and_return(cocina1.new(version: 2), cocina2.new(version: 2))
        perform
      end

      it 'opens a version and refreshes' do
        expect(log).to have_received(:puts).with(/Starting ApplyApoDefaultsJob for BulkAction/)
        expect(log).to have_received(:puts).with(/Successfully applied defaults for druid:bb111cc2222/)
        expect(log).to have_received(:puts).with(/Successfully applied defaults for druid:cc111dd2222/)

        expect(object_client1).to have_received(:apply_admin_policy_defaults)
        expect(object_client2).to have_received(:apply_admin_policy_defaults)
      end
    end
  end

  context 'when dor-services-app fails to find the object' do
    let(:ability) { instance_double(Ability, can?: true) }

    before do
      allow(object_client1).to receive(:find).and_raise(Faraday::TimeoutError)
      allow(object_client2).to receive(:find).and_raise(Faraday::TimeoutError)

      described_class.perform_now(bulk_action.id,
                                  druids:,
                                  groups:,
                                  user:)
    end

    it 'tries again and logs messages' do
      expect(bulk_action.reload.druid_count_fail).to eq 2
      expect(log).to have_received(:puts).with(/Failed Faraday::TimeoutError timeout for druid:bb111cc2222/)
      expect(log).to have_received(:puts).with(/Failed Faraday::TimeoutError timeout for druid:cc111dd2222/)
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    before do
      described_class.perform_now(bulk_action.id,
                                  druids:,
                                  groups:,
                                  user:)
    end

    it 'does not refresh' do
      expect(log).to have_received(:puts).with(/Starting ApplyApoDefaultsJob for BulkAction/)
      expect(log).to have_received(:puts).with(/Not authorized to update for druid:bb111cc2222/)
      expect(log).to have_received(:puts).with(/Not authorized to update for druid:cc111dd2222/)
      expect(object_client1).not_to have_received(:apply_admin_policy_defaults)
      expect(object_client2).not_to have_received(:apply_admin_policy_defaults)
    end
  end
end
