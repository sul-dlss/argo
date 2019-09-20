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

  let(:pids) { %w(druid:bb111cc2222 druid:cc111dd2222 druid:dd111ee2222) }
  let(:catkeys) { %w(12345 6789 44444) }
  let(:buffer) { StringIO.new }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
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
    let(:current_object) { instance_double(Dor::Item, pid: pid, current_version: '3') }
    let(:client) { double(Dor::Services::Client) }
    let(:object) { instance_double(Dor::Services::Client::Object, version: object_version) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object)
      allow(Dor::StateService).to receive(:new).and_return(state_service)
      allow(subject.ability).to receive(:can?).and_return(true)
    end

    context 'when modification is not allowed' do
      let(:state_service) { instance_double(Dor::StateService, allows_modification?: false) }
      let(:object_version) { double(Dor::Services::Client::ObjectVersion, openable?: false) }

      it 'updates catkey and versions objects' do
        expect(Dor).to receive(:find).with(pid).and_return(current_object)
        expect(subject).to receive(:open_new_version).with(current_object, "Catkey updated to #{catkey}")
        expect(current_object).to receive(:catkey=).with(catkey)
        expect(current_object).to receive(:save)
        expect(VersionService).to receive(:close).with(identifier: current_object.pid)
        subject.send(:update_catkey, pid, catkey, buffer)
      end
    end

    context 'when modification is allowed' do
      let(:state_service) { instance_double(Dor::StateService, allows_modification?: true) }
      let(:object_version) { double(Dor::Services::Client::ObjectVersion, openable?: true) }

      it 'updates catkey and does not version objects if not needed' do
        expect(Dor).to receive(:find).with(pid).and_return(current_object)
        expect(subject).not_to receive(:open_new_version).with(current_object, "Catkey updated to #{catkey}")
        expect(current_object).to receive(:catkey=).with(catkey)
        expect(current_object).to receive(:save)
        expect(VersionService).not_to receive(:close).with(identifier: current_object.pid)
        subject.send(:update_catkey, pid, catkey, buffer)
      end
    end
  end
end
