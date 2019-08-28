# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseObjectJob do
  let(:client) { instance_double(Dor::Workflow::Client, create_workflow_by_name: nil) }
  let(:buffer) { StringIO.new }

  before do
    allow(Dor::Config.workflow).to receive(:client).and_return(client)

    # Stub out the file, and send it to a string buffer instead
    allow(subject).to receive(:with_bulk_action_log).and_yield(buffer)
  end

  describe '#perform' do
    let(:bulk_action) do
      create(
        :bulk_action,
        action_type: 'ReleaseObjectJob'
      )
    end
    let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
    let(:params) do
      {
        pids: pids,
        manage_release: { 'to' => 'SEARCHWORKS' },
        webauth: { 'privgroup' => 'dorstuff', 'login' => 'esnowden' }
      }
    end
    let(:item1) { instance_double(Dor::Item) }
    let(:item2) { instance_double(Dor::Item) }

    before do
      allow(Dor).to receive(:find).with(pids[0]).and_return(item1)
      allow(Dor).to receive(:find).with(pids[1]).and_return(item2)
    end

    context 'in a happy world' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
        expect(subject.ability).to receive(:can?).and_return(true).exactly(pids.length).times
        pids.each do |pid|
          stub_release_tags(pid)
        end
      end

      it 'updates the total druid count' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq pids.length
        expect(client).to have_received(:create_workflow_by_name).with(pids[0], 'releaseWF')
        expect(client).to have_received(:create_workflow_by_name).with(pids[1], 'releaseWF')
      end

      it 'increments the bulk_actions druid count success' do
        expect do
          subject.perform(bulk_action.id, params)
        end.to change(bulk_action, :druid_count_success).from(0).to(pids.length)
      end

      it 'logs information to the logfile' do
        subject.perform(bulk_action.id, params)
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
        expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
        expect(subject.ability).to receive(:can?).and_return(true).exactly(pids.length).times
        # no stubbed release wf calls (they should never get called)
        pids.each do |pid|
          stub_release_tags(pid, 500)
        end
      end

      it 'updates the total druid count' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq pids.length
      end

      it 'increments the bulk_actions druid count fail' do
        expect do
          subject.perform(bulk_action.id, params)
        end.to change(bulk_action, :druid_count_fail).from(0).to(pids.length)
      end

      it 'logs information to the logfile' do
        # Stub out the file, and send it to a string buffer instead
        buffer = StringIO.new
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        subject.perform(bulk_action.id, params)
        pids.each do |pid|
          expect(buffer.string).to include "Beginning ReleaseObjectJob for #{pid}"
          expect(buffer.string).to include 'Release tag failed POST Dor::Services::Client::UnexpectedResponse : 500 (Response from dor-services-app did not contain a body.'
        end
        expect(buffer.string).to include 'Adding release tag for SEARCHWORKS'
        expect(buffer.string).not_to include 'Release tag added successfully'
        expect(buffer.string).not_to include 'Trying to start release workflow'
      end
    end

    context 'when a release wf fails' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
        expect(subject.ability).to receive(:can?).and_return(true).exactly(pids.length).times
        allow(client).to receive(:create_workflow_by_name).and_raise(Dor::WorkflowException)
        pids.each do |pid|
          stub_release_tags(pid)
        end
      end

      it 'updates the total druid count' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq pids.length
      end
      it 'increments the bulk_actions druid count fail' do
        expect do
          subject.perform(bulk_action.id, params)
        end.to change(bulk_action, :druid_count_fail).from(0).to(pids.length)
      end
      it 'logs information to the logfile' do
        # Stub out the file, and send it to a string buffer instead
        buffer = StringIO.new
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        subject.perform(bulk_action.id, params)
        pids.each do |pid|
          expect(buffer.string).to include "Beginning ReleaseObjectJob for #{pid}"
          expect(buffer.string).to include 'Workflow creation failed POST Dor::WorkflowException Dor::WorkflowException'
        end
        expect(buffer.string).to include 'Adding release tag for SEARCHWORKS'
        expect(buffer.string).to include 'Release tag added successfully'
        expect(buffer.string).to include 'Trying to start release workflow'
      end
    end

    context 'when not authorized' do
      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
        expect(subject.ability).to receive(:can?).and_return(false).exactly(pids.length).times
      end

      it 'updates the total druid count' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq pids.length
      end
      it 'logs druid info to logfile' do
        buffer = StringIO.new
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        subject.perform(bulk_action.id, params)
        expect(buffer.string).to include 'Starting ReleaseObjectJob for BulkAction'
        pids.each do |pid|
          expect(buffer.string).to include "Beginning ReleaseObjectJob for #{pid}"
          expect(buffer.string).to include "Not authorized for #{pid}"
          expect(buffer.string).not_to include 'Adding release tag for'
        end
        expect(buffer.string).to include 'Finished ReleaseObjectJob for BulkAction'
      end
    end
  end
end

def stub_release_tags(druid, status = 201)
  stub_request(:post, "http://localhost:3003/v1/objects/#{druid}/release_tags")
    .to_return(status: status)
end
