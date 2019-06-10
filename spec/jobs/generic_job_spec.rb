# frozen_string_literal: true

require 'rails_helper'

class GenericTestJob < GenericJob
  def perform(_bulk_action_id, _params)
    bulk_action.increment(:druid_count_success)
    bulk_action.increment(:druid_count_fail)
    bulk_action.increment(:druid_count_total)
    bulk_action.save
  end
end

RSpec.describe GenericJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'GenericJob'
    )
    expect(bulk_action).to receive(:process_bulk_action_type)
    bulk_action.save
    bulk_action
  end

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
  end

  describe '#with_bulk_action_log' do
    it 'opens a log buffer in append mode, and pass it to the block' do
      buffer = StringIO.new
      expect(File).to receive(:open).with(bulk_action_no_process_callback.log_name, 'a').and_yield(buffer)

      subject.with_bulk_action_log do |my_log_buf|
        expect(my_log_buf).to eq buffer
      end
    end
  end

  describe 'before_perform' do
    it 'resets the druid counts before the job gets (re-)run' do
      allow(BulkAction).to receive(:find).with(bulk_action_no_process_callback.id).and_return(bulk_action_no_process_callback)

      GenericTestJob.perform_now(bulk_action_no_process_callback.id, {})
      expect(bulk_action_no_process_callback.druid_count_success).to eq 1
      expect(bulk_action_no_process_callback.druid_count_fail).to eq 1
      expect(bulk_action_no_process_callback.druid_count_total).to eq 1

      GenericTestJob.perform_now(bulk_action_no_process_callback.id, {})
      expect(bulk_action_no_process_callback.druid_count_success).to eq 1
      expect(bulk_action_no_process_callback.druid_count_fail).to eq 1
      expect(bulk_action_no_process_callback.druid_count_total).to eq 1
    end
  end

  describe '#open_new_version' do
    let(:current_user) do
      instance_double(User,
                      is_admin?: true)
    end
    let(:dor_object) { double(pid: 'druid:123abc') }
    let(:workflow) { double('workflow') }
    let(:log) { double('log') }
    let(:webauth) { OpenStruct.new('privgroup' => 'dorstuff', 'login' => 'someuser') }
    let(:client) { instance_double(Dor::Services::Client::Object, open_new_version: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(client)
    end

    it 'opens a new version if the workflow status allows' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(dor_object.pid).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(true)

      subject.send(:open_new_version, dor_object, 'Set new governing APO')

      expect(client).to have_received(:open_new_version).with(
        vers_md_upd_info: {
          significance: 'minor',
          description: 'Set new governing APO',
          opening_user_name: subject.bulk_action.user.to_s
        }
      )
    end

    it 'does not open a new version if rejected by the workflow status' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(dor_object.pid).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(false)
      expect { subject.send(:open_new_version, dor_object, 'Message') }.to raise_error(/Unable to open new version/)

      expect(client).not_to have_received(:open_new_version)
    end

    context 'when something goes wrong updating the version' do
      before do
        allow(client).to receive(:open_new_version).and_raise Dor::Exception
      end

      it 'fails with an exception' do
        expect(DorObjectWorkflowStatus).to receive(:new).with(dor_object.pid).and_return(workflow)
        expect(workflow).to receive(:can_open_version?).and_return(true)
        allow(subject).to receive(:current_user).and_return(current_user)
        expect { subject.send(:open_new_version, dor_object, 'Set new governing APO') }.to raise_error(Dor::Exception)
      end
    end
  end

  describe '#can_manage?' do
    let(:ability_instance) { instance_double(Ability) }
    let(:item) { instance_double(Dor::Item) }
    let(:job) { described_class.new }
    let(:bulk_action) { create(:bulk_action) }

    before do
      expect(Ability).to receive(:new).and_return(ability_instance)
      expect(Dor).to receive(:find).with('druid:abc123').and_return(item)

      # In this test, perform() is not being called. This is what sets these attributes
      allow(job).to receive(:bulk_action).and_return(bulk_action)
      allow(job).to receive(:groups).and_return(['admin'])
    end

    it 'calls parent ability manage' do
      expect_any_instance_of(User).to receive(:set_groups_to_impersonate).with(['admin'])
      expect(ability_instance).to receive(:can?).with(:manage_item, item).and_return false
      expect(job.can_manage?('druid:abc123')).to be false
    end
  end

  describe '#ability' do
    it 'caches the result' do
      ability = double(Ability)
      allow(subject).to receive(:groups).and_return('privgroup' => 'dorstuff', 'login' => 'someuser')
      expect(Ability).to receive(:new).with(bulk_action_no_process_callback.user).and_return(ability).exactly(:once)

      expect(subject.send(:ability)).to be(ability)
      expect(subject.send(:ability)).to be(ability)
    end
  end
end
