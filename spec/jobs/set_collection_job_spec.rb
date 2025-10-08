# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCollectionJob do
  subject(:job) { described_class.new }

  let(:druids) { ['druid:cc111dd2222', 'druid:dd111ff2222'] }
  let(:new_collection_id) { 'druid:bc111bb2222' }
  let(:groups) { [] }
  let(:user) { instance_double(User, to_s: 'amcollie') }
  let(:output_directory) { bulk_action.output_directory }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetCollectionJob',
      log_name: 'tmp/set_collection_job_log.txt'
    )
  end
  let(:cocina1) do
    build(:dro_with_metadata, id: druids[0])
  end
  let(:cocina2) do
    build(:dro_with_metadata, id: druids[1])
  end

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  describe '#perform_now' do
    let(:params) do
      {
        druids:,
        groups:,
        user:,
        new_collection_id:
      }.with_indifferent_access
    end
    let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, update: true) }
    let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, update: true) }

    before do
      allow(VersionService).to receive(:open?).and_return(true)
    end

    context 'with authorization' do
      before do
        allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
        allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
        allow(Ability).to receive(:new).and_return(instance_double(Ability, can?: true))
      end

      context 'when no collections are selected' do
        let(:new_collection_id) { '' }

        it 'removes the collection successfully' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(0)
          expect(bulk_action.druid_count_success).to eq(druids.length)
        end
      end

      context 'when the objects can be modified' do
        context 'when the version is open' do
          it 'sets the new collection on an object' do
            subject.perform(bulk_action.id, params)
            expect(bulk_action.druid_count_total).to eq(druids.length)
            expect(bulk_action.druid_count_fail).to eq(0)
            expect(bulk_action.druid_count_success).to eq(druids.length)
          end
        end

        context 'when the version is closed' do
          before do
            allow(VersionService).to receive_messages(open?: false, openable?: true)
            allow(VersionService).to receive(:open).with(a_hash_including(druid: druids[0])).and_return(cocina1.new(version: 2))
            allow(VersionService).to receive(:open).with(a_hash_including(druid: druids[1])).and_return(cocina2.new(version: 2))
          end

          it 'opens a new version sets the new collection on an object' do
            subject.perform(bulk_action.id, params)
            expect(bulk_action.druid_count_total).to eq(druids.length)
            expect(bulk_action.druid_count_fail).to eq(0)
            expect(bulk_action.druid_count_success).to eq(druids.length)
          end
        end
      end

      context 'when the objects is not found' do
        let(:log) { StringIO.new }

        before do
          allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
          allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_raise(Dor::Services::Client::NotFoundResponse)
          allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_raise(Dor::Services::Client::NotFoundResponse)
        end

        it 'sets the new collection on an object' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq(druids.length)
          expect(bulk_action.druid_count_fail).to eq(druids.length)
          expect(log.string).to include "Failed Dor::Services::Client::NotFoundResponse Dor::Services::Client::NotFoundResponse for #{druids[0]}"
          expect(log.string).to include "Failed Dor::Services::Client::NotFoundResponse Dor::Services::Client::NotFoundResponse for #{druids[1]}"
        end
      end
    end

    context 'without authorization' do
      before do
        allow(Ability).to receive(:new).and_return(instance_double(Ability, can?: false))
      end

      it 'does not set the new collection on an object and increments failure count' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq(druids.length)
        expect(bulk_action.druid_count_fail).to eq(druids.length)
        expect(bulk_action.druid_count_success).to eq(0)
      end
    end
  end
end
