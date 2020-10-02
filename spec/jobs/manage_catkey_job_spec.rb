# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageCatkeyJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'ManageCatkeyjob'
    )
    bulk_action.save
    bulk_action
  end

  let(:webauth) { { 'privgroup' => 'dorstuff', 'login' => 'someuser' } }

  let(:pids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ee2222] }
  let(:catkeys) { %w[12345 6789 44444] }
  let(:buffer) { StringIO.new }
  let(:item1) do
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
  let(:item2) do
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
  let(:item3) do
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
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(pids[2]).and_return(object_client3)
  end

  describe '#perform' do
    it 'attempts to update the catkey for each druid with correct corresponding catkey' do
      params =
        {
          pids: pids,
          manage_catkeys: { 'catkeys' => catkeys.join("\n") },
          webauth: webauth
        }
      expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
      pids.each_with_index do |pid, i|
        expect(subject).to receive(:update_catkey).with(pid, catkeys[i], buffer)
      end
      subject.perform(bulk_action_no_process_callback.id, params)
      expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
    end
  end

  describe '#update_catkey' do
    let(:pid) { pids[0] }
    let(:catkey) { catkeys[0] }
    let(:client) { double(Dor::Services::Client) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: item1, update: true) }
    let(:item1) do
      Cocina::Models.build(
        'label' => 'My Item',
        'version' => 3,
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

    let(:updated_model) do
      item1.new(
        {
          'identification' => {
            'catalogLinks' => [{ catalog: 'symphony', catalogRecordId: '12345' }]
          }
        }
      )
    end

    before do
      allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_client)
      allow(StateService).to receive(:new).and_return(state_service)
      allow(subject.ability).to receive(:can?).and_return(true)
    end

    context 'when modification is not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'updates catkey and versions objects' do
        expect(subject).to receive(:open_new_version).with(pid, 3, "Catkey updated to #{catkey}")
        subject.send(:update_catkey, pid, catkey, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end

    context 'when modification is allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: true) }

      it 'updates catkey and does not version objects if not needed' do
        expect(subject).not_to receive(:open_new_version).with(pid, 3, "Catkey updated to #{catkey}")
        subject.send(:update_catkey, pid, catkey, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end
  end
end
