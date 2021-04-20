# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PrepareJob, type: :job do
  let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:workflow_status) { instance_double(DorObjectWorkflowStatus, can_open_version?: true) }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end
  let(:user) { bulk_action.user }

  let(:cocina1) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 2,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[0],
      'access' => {},
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end
  let(:cocina2) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 3,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[1],
      'access' => {},
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }

  before do
    allow(Ability).to receive(:new).and_return(ability)
    allow(VersionService).to receive(:open)
    allow(DorObjectWorkflowStatus).to receive(:new).and_return(workflow_status)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    it 'opens new versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user,
                                  prepare: {
                                    'description' => 'Changed dates',
                                    'significance' => 'major'
                                  })

      expect(VersionService).to have_received(:open).with(identifier: anything,
                                                          description: 'Changed dates',
                                                          opening_user_name: user.to_s,
                                                          significance: 'major').twice
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it 'does not open new versions' do
      described_class.perform_now(bulk_action.id,
                                  pids: pids,
                                  groups: groups,
                                  user: user,
                                  prepare: {
                                    'description' => 'Changed dates',
                                    'significance' => 'major'
                                  })

      expect(VersionService).not_to have_received(:open)
    end
  end
end
