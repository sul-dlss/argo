# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageEmbargoesJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'SetCatkeysAndBarcodesCsvJob'
    )
    bulk_action.save
    bulk_action
  end

  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:release_dates) { ['2040-04-04', '2030-03-03', ''] }
  let(:rights) { ['world', '', 'stanford-nd'] }
  let(:buffer) { StringIO.new }
  let(:item1) do
    build(:dro, id: druids[0])
  end
  let(:item2) do
    build(:dro, id: druids[1])
  end
  let(:item3) do
    build(:dro, id: druids[2])
  end

  let(:csv_file) do
    [
      'Druid,Release_date,Rights',
      [druids[0], release_dates[0], rights[0]].join(','),
      [druids[1], release_dates[1], rights[1]].join(','),
      [druids[2], release_dates[2], rights[2]].join(',')
    ].join("\n")
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:change_set1) { instance_double(ItemChangeSet, validate: true, save: true) }
  let(:change_set2) { instance_double(ItemChangeSet, validate: true, save: true) }
  let(:change_set3) { instance_double(ItemChangeSet, validate: true, save: true) }

  let(:params) do
    {
      druids: druids,
      csv_file: csv_file
    }
  end

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(subject.ability).to receive(:can?).and_return(true)
    allow(BulkJobLog).to receive(:open).and_yield(buffer)
    allow(VersionService).to receive(:open)
    allow(ItemChangeSet).to receive(:new).and_return(change_set1, change_set2, change_set3)
    allow(DorObjectWorkflowStatus).to receive(:new).with(druids[0], version: item1.version).and_return(instance_double(DorObjectWorkflowStatus, can_open_version?: true))
    allow(DorObjectWorkflowStatus).to receive(:new).with(druids[1], version: item2.version).and_return(instance_double(DorObjectWorkflowStatus, can_open_version?: true))
    allow(DorObjectWorkflowStatus).to receive(:new).with(druids[2], version: item3.version).and_return(instance_double(DorObjectWorkflowStatus, can_open_version?: true))
  end

  describe '#perform' do
    context 'when not authorized' do
      before do
        allow(subject.ability).to receive(:can?).and_return(false)
      end

      it 'logs and returns' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(buffer.string).to include('Not authorized')
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
      end
    end

    context 'when modification is allowed' do
      it 'updates the embargo' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(ItemChangeSet).to have_received(:new).with(item1)
        expect(change_set1).to have_received(:validate).with(embargo_release_date: DateTime.parse(release_dates[0]),
                                                             embargo_access: 'world')
        expect(change_set1).to have_received(:save)
        expect(ItemChangeSet).to have_received(:new).with(item2)
        expect(change_set2).to have_received(:validate).with(embargo_release_date: DateTime.parse(release_dates[1]))
        expect(change_set2).to have_received(:save)
        expect(ItemChangeSet).to have_received(:new).with(item3)
        expect(change_set3).to have_received(:validate).with(embargo_access: 'stanford-nd')
        expect(change_set3).to have_received(:save)

        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
        expect(VersionService).not_to have_received(:open)
        expect(DorObjectWorkflowStatus).not_to have_received(:new)
      end
    end

    context 'when modification is not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'opens new version and updates the embargo' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(change_set1).to have_received(:save)
        expect(change_set2).to have_received(:save)
        expect(change_set3).to have_received(:save)
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
        expect(VersionService).to have_received(:open).exactly(3).times
      end
    end

    context 'when error' do
      before do
        allow(state_service).to receive(:allows_modification?).and_raise('oops')
      end

      it 'logs' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(buffer.string).to include('Embargo failed')
      end
    end

    context 'when bad date' do
      let(:release_dates) { ['2040-04-04', 'foo', ''] }

      it 'updates the embargo and logs the bad date' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(change_set1).to have_received(:save)
        expect(change_set2).to have_received(:save)
        expect(change_set3).not_to have_received(:save)
        expect(bulk_action_no_process_callback.druid_count_fail).to eq 1
        expect(buffer.string).to include('foo is not a valid date')
      end
    end

    context 'when bad right' do
      let(:rights) { ['world', '', 'stanford-nobody'] }
      let(:change_set3) { instance_double(ItemChangeSet, validate: false, save: true) }

      it 'updates the embargo and logs the bad right' do
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(change_set1).to have_received(:save)
        expect(change_set2).to have_received(:save)
        expect(change_set3).not_to have_received(:save)
        expect(bulk_action_no_process_callback.druid_count_fail).to eq 1
        expect(buffer.string).to include('stanford-nobody is not a valid right')
      end
    end
  end
end
