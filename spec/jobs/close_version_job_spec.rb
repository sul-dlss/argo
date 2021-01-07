# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CloseVersionJob, type: :job do
  let(:pids) { ['druid:bc123df4567', 'druid:bc123df4598'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end
  let(:item1) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 1,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[0],
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end
  let(:item2) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 1,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[1],
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1, version: version_client) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2, version: version_client) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'closes versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)

      expect(version_client).to have_received(:close).twice
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not close versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user)

      expect(version_client).not_to have_received(:close)
    end
  end
end
