# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCollectionJob do
  let(:pids) { ['druid:cc111dd2222', 'druid:dd111ff2222'] }
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

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  after do
    FileUtils.rm_rf(output_directory) if Dir.exist?(output_directory)
  end

  describe '#perform_now' do
    let(:params) do
      {
        pids: pids,
        groups: groups,
        user: user,
        set_collection: { 'new_collection_id' => new_collection_id }
      }
    end
    let(:cocina1) do
      Cocina::Models.build({
                             'label' => 'My First Item',
                             'version' => 2,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pids[0],
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end
    let(:cocina2) do
      Cocina::Models.build({
                             'label' => 'My Second Item',
                             'version' => 2,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pids[1],
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end
    let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, update: true) }
    let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina2, update: true) }
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    context 'with authorization' do
      before do
        allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
        allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
        allow(StateService).to receive(:new).and_return(state_service)
      end

      context 'when the objects can be updated' do
        before do
          allow(subject).to receive(:check_can_set_collection!).with(cocina1, state_service).and_return true
          allow(subject).to receive(:check_can_set_collection!).with(cocina2, state_service).and_return true
        end

        it 'sets the new collection on an object' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq(pids.length)
          expect(bulk_action.druid_count_fail).to eq(0)
          expect(bulk_action.druid_count_success).to eq(pids.length)
        end
      end

      context 'when the objects is not found' do
        let(:buffer) { StringIO.new }

        before do
          allow(subject).to receive(:with_bulk_action_log).and_yield(buffer)
          allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_raise(Dor::Services::Client::NotFoundResponse)
          allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_raise(Dor::Services::Client::NotFoundResponse)
        end

        it 'sets the new collection on an object' do
          subject.perform(bulk_action.id, params)
          expect(bulk_action.druid_count_total).to eq(pids.length)
          expect(bulk_action.druid_count_fail).to eq(pids.length)
          expect(buffer.string).to include "SetCollectionJob: Unexpected error for #{pids[0]} (bulk_action.id=#{bulk_action.id}): Dor::Services::Client::NotFoundResponse"
          expect(buffer.string).to include "SetCollectionJob: Unexpected error for #{pids[1]} (bulk_action.id=#{bulk_action.id}): Dor::Services::Client::NotFoundResponse"
        end
      end
    end

    context 'without authorization' do
      before do
        allow(subject).to receive(:check_can_set_collection!).with(cocina1, state_service).and_return false
        allow(subject).to receive(:check_can_set_collection!).with(cocina2, state_service).and_return false
      end

      it 'does not set the new collection on an object and increments failure count' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq(pids.length)
        expect(bulk_action.druid_count_fail).to eq(pids.length)
        expect(bulk_action.druid_count_success).to eq(0)
      end
    end
  end
end
