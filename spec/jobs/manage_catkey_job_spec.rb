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
    let(:current_object) { double(Dor::Item) }

    it 'updates catkey and versions objects' do
      allow(subject).to receive(:can_manage?).and_return(true)
      allow(current_object).to receive(:allows_modification?).and_return(false)
      allow(current_object).to receive(:new_version_open?).and_return(true)
      allow(current_object).to receive(:pid).and_return(pid)
      expect(Dor).to receive(:find).with(pid).and_return(current_object)
      expect(subject).to receive(:open_new_version).with(current_object, "Catkey updated to #{catkey}")
      expect(current_object).to receive(:catkey=).with(catkey)
      expect(current_object).to receive(:save)
      expect(subject).to receive(:close_version).with(current_object)
      subject.send(:update_catkey, pid, catkey, buffer)
    end

    it 'updates catkey and does not version objects if not needed' do
      allow(subject).to receive(:can_manage?).and_return(true)
      allow(current_object).to receive(:allows_modification?).and_return(true)
      allow(current_object).to receive(:new_version_open?).and_return(false)
      allow(current_object).to receive(:pid).and_return(pid)
      expect(Dor).to receive(:find).with(pid).and_return(current_object)
      expect(subject).not_to receive(:open_new_version).with(current_object, "Catkey updated to #{catkey}")
      expect(current_object).to receive(:catkey=).with(catkey)
      expect(current_object).to receive(:save)
      expect(subject).not_to receive(:close_version).with(current_object)
      subject.send(:update_catkey, pid, catkey, buffer)
    end
  end
end
