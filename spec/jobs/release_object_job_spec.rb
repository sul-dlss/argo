require 'spec_helper'

describe ReleaseObjectJob do
  describe '#perform' do
    let(:bulk_action_no_process_callback) do
      bulk_action = build(
        :bulk_action,
        action_type: 'ReleaseObjectJob'
      )
      expect(bulk_action).to receive(:process_bulk_action_type)
      bulk_action.save
      bulk_action
    end
    let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
    let(:params) do
      {
        pids: pids,
        manage_release: { 'to' => 'SEARCHWORKS' },
        webauth: { 'privgroup' => 'dorstuff', 'login' => 'esnowden' }
      }
    end
    context 'in a happy world' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback).at_least(:once)
        expect(subject).to receive(:can_manage?).and_return(true).exactly(pids.length).times
        pids.each do |pid|
          stub_release_tags(pid)
          stub_release_wf(pid)
        end
      end
      it 'updates the total druid count' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
      end
      it 'increments the bulk_actions druid count success' do
        expect do
          subject.perform(bulk_action_no_process_callback.id, params)
        end.to change{bulk_action_no_process_callback.druid_count_success}.from(0).to(pids.length)
      end
      it 'logs information to the logfile' do
        # Stub out the file, and send it to a string buffer instead
        buffer = StringIO.new
        expect(File).to receive(:open).with(bulk_action_no_process_callback.log_name, 'w').and_yield(buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(buffer.string).to include 'Starting ReleaseObjectJob for BulkAction'
        pids.each do |pid|
          expect(buffer.string).to include "Beginning ReleaseObjectJob for #{pid}"
        end
        expect(buffer.string).to include 'Adding release tag for SEARCHWORKS'
        expect(buffer.string).to include 'Release tag added successfully'
        expect(buffer.string).to include 'Trying to start release workflow'
        expect(buffer.string).to include 'Workflow creation successful'
        expect(buffer.string).to include 'Finished ReleaseObjectJob for BulkAction'
      end
    end
    context 'when a release tag fails' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback).at_least(:once)
        expect(subject).to receive(:can_manage?).and_return(true).exactly(pids.length).times
        # no stubbed release wf calls (they should never get called)
        pids.each do |pid|
          stub_release_tags(pid, 500)
        end
      end
      it 'updates the total druid count' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
      end
      it 'increments the bulk_actions druid count fail' do
        expect do
          subject.perform(bulk_action_no_process_callback.id, params)
        end.to change{bulk_action_no_process_callback.druid_count_fail}.from(0).to(pids.length)
      end
      it 'logs information to the logfile' do
        # Stub out the file, and send it to a string buffer instead
        buffer = StringIO.new
        expect(File).to receive(:open).with(bulk_action_no_process_callback.log_name, 'w').and_yield(buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        pids.each do |pid|
          expect(buffer.string).to include "Beginning ReleaseObjectJob for #{pid}"
          expect(buffer.string).to include "Release tag failed POST https://dor-services.example.com/dor/v1/objects/#{pid}/release_tags, status: 500"
        end
        expect(buffer.string).to include 'Adding release tag for SEARCHWORKS'
        expect(buffer.string).to_not include 'Release tag added successfully'
        expect(buffer.string).to_not include 'Trying to start release workflow'
      end
    end
    context 'when a release wf fails' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback).at_least(:once)
        expect(subject).to receive(:can_manage?).and_return(true).exactly(pids.length).times
        pids.each do |pid|
          stub_release_tags(pid)
          stub_release_wf(pid, 500)
        end
      end
      it 'updates the total druid count' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
      end
      it 'increments the bulk_actions druid count fail' do
        expect do
          subject.perform(bulk_action_no_process_callback.id, params)
        end.to change{bulk_action_no_process_callback.druid_count_fail}.from(0).to(pids.length)
      end
      it 'logs information to the logfile' do
        # Stub out the file, and send it to a string buffer instead
        buffer = StringIO.new
        expect(File).to receive(:open).with(bulk_action_no_process_callback.log_name, 'w').and_yield(buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        pids.each do |pid|
          expect(buffer.string).to include "Beginning ReleaseObjectJob for #{pid}"
          expect(buffer.string).to include "Workflow creation failed POST https://dor-services.example.com/dor/v1/objects/#{pid}/apo_workflows/releaseWF, status: 500"
        end
        expect(buffer.string).to include 'Adding release tag for SEARCHWORKS'
        expect(buffer.string).to include 'Release tag added successfully'
        expect(buffer.string).to include 'Trying to start release workflow'
      end
    end
    context 'when not authorized' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback).at_least(:once)
        expect(subject).to receive(:can_manage?).and_return(false).exactly(pids.length).times
      end
      it 'updates the total druid count' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
      end
      # no information leakage to an unauthorized user
      it 'logs no druid info to logfile' do
        # Stub out the file, and send it to a string buffer instead
        buffer = StringIO.new
        expect(File).to receive(:open).with(bulk_action_no_process_callback.log_name, 'w').and_yield(buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(buffer.string).to include 'Starting ReleaseObjectJob for BulkAction'
        pids.each do |pid|
          expect(buffer.string).to_not include "Beginning ReleaseObjectJob for #{pid}"
        end
        expect(buffer.string).to include 'Finished ReleaseObjectJob for BulkAction'
      end
    end
    describe 'receives and sets params' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback).at_least(:once)
        expect(subject).to receive(:can_manage?).and_return(true).exactly(pids.length).times
        pids.each do |pid|
          stub_release_tags(pid)
          stub_release_wf(pid)
        end
      end
      it 'webauth converted to OpenStruct' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(subject.webauth).to be_an OpenStruct
        expect(subject.webauth.privgroup).to eq 'dorstuff'
        expect(subject.webauth.login).to eq 'esnowden'
      end
    end
  end
  describe '#can_manage?' do
    let(:ability_instance) { instance_double(Ability) }
    let(:dor_double) { double('Dor') }
    before do
      expect(Ability).to receive(:new).and_return(ability_instance)
      expect(Dor).to receive(:find).with('druid:abc123').and_return(dor_double)
      expect(subject).to receive(:webauth).and_return(double(privgroup: 'dorstuff', login: 'esnowden'))
    end
    it 'calls parent ability manage' do
      expect(ability_instance).to receive(:can?).with(:manage_item, dor_double).and_return false
      expect(subject.can_manage?('druid:abc123')).to be false
    end
  end
end

def stub_release_tags(druid, status = 201)
  stub_request(:post, "https://dor-services.example.com/dor/v1/objects/#{druid}/release_tags")
    .to_return(status: status)
end

def stub_release_wf(druid, status = 201)
  stub_request(:post, "https://dor-services.example.com/dor/v1/objects/#{druid}/apo_workflows/releaseWF")
    .to_return(status: status)
end
