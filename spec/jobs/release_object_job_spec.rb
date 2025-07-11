# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseObjectJob do
  let(:buffer) { StringIO.new }
  let(:item1) { build(:dro_with_metadata, id: druids[0], version: 2) }
  let(:item2) { build(:dro_with_metadata, id: druids[1], version: 3) }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, update: true, workflow: workflow_client) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, update: true, workflow: workflow_client) }
  let(:release_tags) { instance_double(Dor::Services::Client::ReleaseTags) }

  before do
    allow(Repository).to receive(:find).with(druids[0]).and_return(item1)
    allow(Repository).to receive(:find).with(druids[1]).and_return(item2)
    allow(WorkflowService).to receive(:published?).and_return(published)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(object_client1).to receive(:release_tags).and_return(release_tags)
    allow(object_client2).to receive(:release_tags).and_return(release_tags)

    # Stub out the file, and send it to a string buffer instead
    allow(BulkJobLog).to receive(:open).and_yield(buffer)
  end

  describe '#perform' do
    let(:bulk_action) do
      create(
        :bulk_action,
        action_type: 'ReleaseObjectJob'
      )
    end
    let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222'] }
    let(:params) do
      {
        druids:,
        to: 'SEARCHWORKS',
        who: 'bergeraj',
        what: 'self',
        tag: 'true'
      }.with_indifferent_access
    end

    context 'with already published objects' do
      let(:published) { true }
      let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: nil) }

      context 'when happy path' do
        before do
          allow(release_tags).to receive(:create).and_return(true)
          expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
          expect(subject.ability).to receive(:can?).and_return(true).exactly(druids.length).times
        end

        it 'updates the total druid count' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq druids.length
          expect(workflow_client).to have_received(:create).with(version: 2).once
          expect(workflow_client).to have_received(:create).with(version: 3).once
        end

        it 'increments the bulk_actions druid count success' do
          expect do
            subject.perform(bulk_action.id, params)
          end.to change(bulk_action, :druid_count_success).from(0).to(druids.length)
        end

        it 'logs information to the logfile' do
          subject.perform(bulk_action.id, params)
          expect(buffer.string).to include 'Starting ReleaseObjectJob for BulkAction'
          expect(buffer.string).to include 'Workflow creation successful'
          expect(buffer.string).to include 'Finished ReleaseObjectJob for BulkAction'
        end
      end

      context 'when a release tag fails' do
        before do
          expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
          expect(subject.ability).to receive(:can?).and_return(true).exactly(druids.length).times
          allow(release_tags).to receive(:create).and_raise(Dor::Services::Client::UnexpectedResponse)
        end

        it 'updates the total druid count' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq druids.length
        end

        it 'increments the bulk_actions druid count fail' do
          expect do
            subject.perform(bulk_action.id, params)
          end.to change(bulk_action, :druid_count_fail).from(0).to(druids.length)
        end

        it 'logs information to the logfile' do
          # Stub out the file, and send it to a string buffer instead
          buffer = StringIO.new
          expect(BulkJobLog).to receive(:open).and_yield(buffer)
          subject.perform(bulk_action.id, params)
          expect(buffer.string).to include 'Release tag failed'
        end
      end

      context 'when a release wf fails' do
        before do
          expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
          expect(subject.ability).to receive(:can?).and_return(true).exactly(druids.length).times
          allow(workflow_client).to receive(:create).and_raise(Dor::Services::Client::UnexpectedResponse)
          allow(release_tags).to receive(:create).and_raise(Dor::Services::Client::UnexpectedResponse)
        end

        it 'updates the total druid count' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq druids.length
        end

        it 'increments the bulk_actions druid count fail' do
          expect do
            subject.perform(bulk_action.id, params)
          end.to change(bulk_action, :druid_count_fail).from(0).to(druids.length)
        end

        it 'logs information to the logfile' do
          # Stub out the file, and send it to a string buffer instead
          buffer = StringIO.new
          expect(BulkJobLog).to receive(:open).and_yield(buffer)
          subject.perform(bulk_action.id, params)
          expect(buffer.string).to include 'Release tag failed'
        end
      end

      context 'when not authorized' do
        before do
          expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
          expect(subject.ability).to receive(:can?).and_return(false).exactly(druids.length).times
        end

        it 'updates the total druid count' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq druids.length
        end

        it 'logs druid info to logfile' do
          buffer = StringIO.new
          expect(BulkJobLog).to receive(:open).and_yield(buffer)
          subject.perform(bulk_action.id, params)
          expect(buffer.string).to include 'Starting ReleaseObjectJob for BulkAction'
          druids.each do |druid|
            expect(buffer.string).to include "Not authorized for #{druid}"
          end
          expect(buffer.string).to include 'Finished ReleaseObjectJob for BulkAction'
        end
      end
    end

    context 'when objects have never been published' do
      let(:published) { false }
      let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: nil) }

      before do
        expect(subject).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
        expect(subject.ability).not_to receive(:can?)
      end

      it 'does not create workflows' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(workflow_client).not_to have_received(:create).with(version: 2)
        expect(workflow_client).not_to have_received(:create).with(version: 3)
      end

      it 'does not increments the bulk_actions druid count success' do
        expect do
          subject.perform(bulk_action.id, params)
        end.not_to change(bulk_action, :druid_count_success)
      end
    end
  end
end
