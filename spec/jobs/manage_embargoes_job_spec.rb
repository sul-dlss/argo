# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ManageEmbargoesJob do
  let(:bulk_action) { create(:bulk_action, action_type: 'ManageEmbargoesJob') }
  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:release_dates) { %w[2040-04-04 2030-03-03 2035-07-27] }
  let(:rights) { [%w[world world], %w[world world], %w[stanford stanford]] }

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
      'druid,release_date,view,download',
      [druids[0], release_dates[0], *rights[0]].join(','),
      [druids[1], release_dates[1], *rights[1]].join(','),
      [druids[2], release_dates[2], *rights[2]].join(',')
    ].join("\n")
  end

  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:params) { { csv_file: } }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Repository).to receive(:find).with(druids[0]).and_return(item1)
    allow(Repository).to receive(:find).with(druids[1]).and_return(item2)
    allow(Repository).to receive(:find).with(druids[2]).and_return(item3)
    allow(Repository).to receive(:store)

    allow(StateService).to receive(:new).and_return(state_service)
    allow(subject.ability).to receive(:can?).and_return(true)
    allow(BulkJobLog).to receive(:open).and_yield(buffer)
    allow(subject).to receive(:open_new_version).and_return(item1.new(version: 2), item2.new(version: 2), item3.new(version: 2))
  end

  describe '#perform' do
    context 'when not authorized' do
      before do
        allow(subject.ability).to receive(:can?).and_return(false)
      end

      it 'logs and returns' do
        subject.perform(bulk_action.id, params)
        expect(buffer.string).to include('Not authorized')
        expect(bulk_action.druid_count_total).to eq druids.length
      end
    end

    context 'when modification is allowed' do
      it 'updates the embargo' do
        subject.perform(bulk_action.id, params)
        expect(Repository).to have_received(:store).exactly(3).times
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(subject).not_to have_received(:open_new_version)
      end
    end

    context 'when modification is not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'opens new version and updates the embargo' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq 3
        expect(bulk_action.druid_count_success).to eq 3
        expect(Repository).to have_received(:store).exactly(3).times
        expect(subject).to have_received(:open_new_version).exactly(3).times
      end
    end

    context 'when error' do
      before do
        allow(state_service).to receive(:allows_modification?).and_raise('oops')
      end

      it 'logs' do
        subject.perform(bulk_action.id, params)
        expect(buffer.string).to include('Embargo failed')
      end
    end

    context 'when bad date' do
      let(:release_dates) { ['2040-04-04', 'foo', ''] }

      it 'updates the embargo and logs the bad date' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq 3
        expect(bulk_action.druid_count_fail).to eq 2
        expect(bulk_action.druid_count_success).to eq 1
        expect(Repository).to have_received(:store).once
        expect(buffer.string).to include('foo is not a valid date')
        expect(buffer.string).to include('Missing required value for "release_date"')
      end
    end

    context 'when invalid access combination' do
      let(:rights) { [%w[world world], %w[world world], %w[stanford nobody]] }
      let(:change_set3) { instance_double(ItemChangeSet, validate: false, save: true) }

      it 'logs the invalid items' do
        subject.perform(bulk_action.id, params)

        expect(bulk_action.druid_count_total).to eq 3
        expect(bulk_action.druid_count_success).to eq 2
        expect(bulk_action.druid_count_fail).to eq 1
        expect(Repository).to have_received(:store).exactly(2).times
        expect(buffer.string).to include('Download access "nobody" is not a valid option')
      end
    end
  end
end
