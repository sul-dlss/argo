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
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'GenericJob'
    )
  end

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
  end

  describe '#with_bulk_action_log' do
    it 'opens a log buffer in append mode, and pass it to the block' do
      buffer = StringIO.new
      expect(File).to receive(:open).with(bulk_action.log_name, 'a').and_yield(buffer)

      subject.with_bulk_action_log do |my_log_buf|
        expect(my_log_buf).to eq buffer
      end
    end
  end

  describe 'before_perform' do
    it 'resets the druid counts before the job gets (re-)run' do
      allow(BulkAction).to receive(:find).with(bulk_action.id).and_return(bulk_action)

      GenericTestJob.perform_now(bulk_action.id, {})
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_total).to eq 1

      GenericTestJob.perform_now(bulk_action.id, {})
      expect(bulk_action.druid_count_success).to eq 1
      expect(bulk_action.druid_count_fail).to eq 1
      expect(bulk_action.druid_count_total).to eq 1
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
    let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(client)
    end

    it 'opens a new version if the workflow status allows' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(dor_object.pid).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(true)

      subject.send(:open_new_version, dor_object, 'Set new governing APO')

      expect(version_client).to have_received(:open).with(
        significance: 'minor',
        description: 'Set new governing APO',
        opening_user_name: subject.bulk_action.user.to_s
      )
    end

    it 'does not open a new version if rejected by the workflow status' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(dor_object.pid).and_return(workflow)
      expect(workflow).to receive(:can_open_version?).and_return(false)
      expect { subject.send(:open_new_version, dor_object, 'Message') }.to raise_error(/Unable to open new version/)

      expect(version_client).not_to have_received(:open)
    end

    context 'when something goes wrong updating the version' do
      before do
        allow(version_client).to receive(:open).and_raise Dor::Exception
      end

      it 'fails with an exception' do
        expect(DorObjectWorkflowStatus).to receive(:new).with(dor_object.pid).and_return(workflow)
        expect(workflow).to receive(:can_open_version?).and_return(true)
        allow(subject).to receive(:current_user).and_return(current_user)
        expect { subject.send(:open_new_version, dor_object, 'Set new governing APO') }.to raise_error(Dor::Exception)
      end
    end
  end
end
