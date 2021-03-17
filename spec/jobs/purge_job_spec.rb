# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeJob, type: :job do
  let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'jcoyne85') }
  let(:client) { instance_double(Dor::Workflow::Client, lifecycle: submitted) }
  let(:submitted) { false }
  let(:bulk_action) do
    create(:bulk_action,
           log_name: 'foo.txt')
  end
  let(:item1) { instance_double(Dor::Item, delete: true) }
  let(:item2) { instance_double(Dor::Item, delete: true) }

  let(:cocina1) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 2,
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
  let(:cocina2) do
    Cocina::Models.build(
      'label' => 'My Item',
      'version' => 3,
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

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(client)
    allow(Ability).to receive(:new).and_return(ability)
    allow(Dor).to receive(:find).with(pids[0]).and_return(item1)
    allow(Dor).to receive(:find).with(pids[1]).and_return(item2)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
    allow(PurgeService).to receive(:purge)

    described_class.perform_now(bulk_action.id,
                                pids: pids,
                                groups: groups,
                                user: user)
  end

  after do
    FileUtils.rm('foo.txt')
  end

  context 'with manage ability' do
    let(:ability) { instance_double(Ability, can?: true) }

    context 'when submitted' do
      let(:submitted) { true }

      it "doesn't purge" do
        expect(PurgeService).not_to have_received(:purge)
      end
    end

    context 'when not submitted' do
      let(:submitted) { false }

      it 'purges objects' do
        expect(PurgeService).to have_received(:purge).with(druid: pids[0])
        expect(PurgeService).to have_received(:purge).with(druid: pids[1])
      end
    end
  end

  context 'without manage ability' do
    let(:ability) { instance_double(Ability, can?: false) }

    it "doesn't purge" do
      expect(item1).not_to have_received(:delete)
      expect(item2).not_to have_received(:delete)
    end
  end
end
