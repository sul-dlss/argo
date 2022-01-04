# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetGoverningApoJob do
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetGoverningApoJob'
    )
  end

  let(:new_apo_id) { 'druid:aa111bb2222' }
  let(:webauth) { { 'privgroup' => 'dorstuff', 'login' => 'someuser' } }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
  end

  describe '#perform' do
    let(:pids) { ['druid:bb111cc2222', 'druid:cc111dd2222', 'druid:dd111ff2222'] }
    let(:params) do
      {
        pids: pids,
        set_governing_apo: { 'new_apo_id' => new_apo_id },
        webauth: webauth
      }
    end

    let(:buffer) { StringIO.new }

    before do
      allow(subject).to receive(:with_bulk_action_log).and_yield(buffer)
    end

    context 'in a happy world' do
      before do
        allow(StateService).to receive(:new).and_return(state_service)
      end

      let(:state_service) { instance_double(StateService, allows_modification?: true) }

      it 'updates the total druid count, attempts to update the APO for each druid, and commits to solr' do
        pids.each do |pid|
          expect(subject).to receive(:set_governing_apo_and_index_safely).with(pid, buffer)
        end
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq pids.length
      end

      it 'logs info about progress' do
        allow(subject).to receive(:set_governing_apo_and_index_safely)
        allow(Argo::Indexer).to receive(:reindex_pid_remotely)

        subject.perform(bulk_action.id, params)

        bulk_action_id = bulk_action.id
        expect(buffer.string).to include "Starting SetGoverningApoJob for BulkAction #{bulk_action_id}"
        pids.each do |pid|
          expect(buffer.string).to include "SetGoverningApoJob: Starting update for #{pid} (bulk_action.id=#{bulk_action_id})"
          expect(buffer.string).to include "SetGoverningApoJob: Finished update for #{pid} (bulk_action.id=#{bulk_action_id})"
        end
        expect(buffer.string).to include "Finished SetGoverningApoJob for BulkAction #{bulk_action_id}"
      end

      context 'when an individual update fails' do
        let(:cocina1) do
          Cocina::Models.build({
                                 'label' => 'My Item',
                                 'version' => 2,
                                 'type' => Cocina::Models::Vocab.object,
                                 'externalIdentifier' => pids[0],
                                 'access' => {},
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                                 'structural' => {},
                                 'identification' => {}
                               })
        end
        let(:cocina3) do
          Cocina::Models.build({
                                 'label' => 'My Item',
                                 'version' => 3,
                                 'type' => Cocina::Models::Vocab.object,
                                 'externalIdentifier' => pids[2],
                                 'access' => {},
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                                 'structural' => {},
                                 'identification' => {}
                               })
        end

        let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, update: true) }
        let(:object_client3) { instance_double(Dor::Services::Client::Object, find: cocina3) }

        before do
          allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
          allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_raise(Dor::Services::Client::NotFoundResponse)
          allow(Dor::Services::Client).to receive(:object).with(pids[2]).and_return(object_client3)

          allow(subject).to receive(:check_can_set_governing_apo!).with(cocina1, state_service).and_return true
          allow(subject).to receive(:check_can_set_governing_apo!).with(cocina3, state_service).and_raise('user not allowed to move to target apo')
        end

        # it might be cleaner to break the testing here into smaller cases for #set_governing_apo_and_index_safely,
        # assuming one is inclined to test private methods, but it also seemed reasonable to do a slightly more end-to-end
        # test of #perform, to prove that common failure cases for individual objects wouldn't fail the whole run.
        it 'increments the failure and success counts and logs status of each update' do
          expect(Argo::Indexer).to receive(:reindex_pid_remotely)

          subject.perform(bulk_action.id, params)
          expect(state_service).to have_received(:allows_modification?)
          expect(object_client1).to have_received(:update).with(params: Cocina::Models::DRO)

          expect(bulk_action.druid_count_success).to eq 1
          expect(bulk_action.druid_count_fail).to eq 2

          bulk_action_id = bulk_action.id
          expect(buffer.string).to include "SetGoverningApoJob: Successfully updated #{pids[0]} (bulk_action.id=#{bulk_action_id})"
          expect(buffer.string).to include "SetGoverningApoJob: Unexpected error for #{pids[1]} (bulk_action.id=#{bulk_action_id}): Dor::Services::Client::NotFoundResponse"
          expect(buffer.string).to include "SetGoverningApoJob: Unexpected error for #{pids[2]} (bulk_action.id=#{bulk_action_id}): user not allowed to move to target apo"
        end
      end
    end
  end

  describe '#check_can_set_governing_apo!' do
    let(:pid) { 'druid:bc123df4567' }
    let(:ability) { double(Ability) }
    let(:obj) do
      Cocina::Models.build({
                             'label' => 'My Item',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end

    before do
      subject.instance_variable_set(:@new_apo_id, new_apo_id)
      subject.instance_variable_set(:@ability, ability)
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'when modification is allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: true) }

      it "gets an object that the user can't manage" do
        allow(ability).to receive(:can?).with(:manage_governing_apo, obj, new_apo_id).and_return(false)
        expect { subject.send(:check_can_set_governing_apo!, obj, state_service) }.to raise_error("user not authorized to move #{pid} to #{new_apo_id}")
      end

      it 'gets an object that the user can manage' do
        allow(ability).to receive(:can?).with(:manage_governing_apo, obj, new_apo_id).and_return(true)
        expect { subject.send(:check_can_set_governing_apo!, obj, state_service) }.not_to raise_error
      end
    end

    context 'when modification is not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it "gets an object that doesn't allow modification, that the user can manage" do
        allow(ability).to receive(:can?).with(:manage_governing_apo, obj, new_apo_id).and_return(true)
        expect { subject.send(:check_can_set_governing_apo!, obj, state_service) }.to raise_error("#{pid} is not open for modification")
      end

      it "gets an object that doesn't allow modification, that the user can't manage" do
        allow(ability).to receive(:can?).with(:manage_governing_apo, obj, new_apo_id).and_return(false)
        expect { subject.send(:check_can_set_governing_apo!, obj, state_service) }.to raise_error("#{pid} is not open for modification")
      end
    end
  end
end
