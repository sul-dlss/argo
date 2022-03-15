# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyApoDefaultsJob, type: :job do
  let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:bulk_action) { create(:bulk_action) }
  let(:user) { bulk_action.user }

  let(:identification) do
    { catalogLinks: [{ catalog: 'symphony', catalogRecordId: '123' }] }
  end

  let(:cocina1) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 2,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pids[0],
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'description' => { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/bb111cc2222' },
                           'structural' => {},
                           'identification' => identification
                         })
  end
  let(:cocina2) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 3,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => pids[1],
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'description' => { title: [{ value: 'Stored title' }], purl: 'https://purl.stanford.edu/cc111dd2222' },
                           'structural' => {},
                           'identification' => identification
                         })
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, apply_admin_policy_defaults: true) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, apply_admin_policy_defaults: true) }
  let(:logger) { double('logger', puts: nil) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
    allow(BulkJobLog).to receive(:open).and_yield(logger)
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    before do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)
    end

    it 'refreshes' do
      expect(logger).to have_received(:puts).with(/Starting ApplyApoDefaultsJob for BulkAction/)
      expect(logger).to have_received(:puts).with(/Successfully applied defaults to druid:bb111cc2222/)
      expect(logger).to have_received(:puts).with(/Successfully applied defaults to druid:cc111dd2222/)

      expect(object_client1).to have_received(:apply_admin_policy_defaults)
      expect(object_client2).to have_received(:apply_admin_policy_defaults)
    end
  end

  context 'when dor-services-app fails to find the object' do
    let(:ability) { instance_double(Ability, can?: true) }

    before do
      allow(object_client1).to receive(:find).and_raise(Faraday::TimeoutError)
      allow(object_client2).to receive(:find).and_raise(Faraday::TimeoutError)

      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)
    end

    it 'tries again and logs messages' do
      expect(bulk_action.reload.druid_count_fail).to eq 2
      expect(logger).to have_received(:puts).with(/Unexpected error for druid:bb111cc2222/)
      expect(logger).to have_received(:puts).with(/Unexpected error for druid:cc111dd2222/)
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    before do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)
    end

    it 'does not refresh' do
      expect(logger).to have_received(:puts).with(/Starting ApplyApoDefaultsJob for BulkAction/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:bb111cc2222/)
      expect(logger).to have_received(:puts).with(/Not authorized for druid:cc111dd2222/)
      expect(object_client1).not_to have_received(:apply_admin_policy_defaults)
      expect(object_client2).not_to have_received(:apply_admin_policy_defaults)
    end
  end
end