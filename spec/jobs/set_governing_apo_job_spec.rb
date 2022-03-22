# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetGoverningApoJob do
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'SetGoverningApoJob'
    )
  end

  let(:new_apo_id) { 'druid:bc111bb2222' }
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
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    before do
      allow(BulkJobLog).to receive(:open).and_yield(buffer)
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'when the user can modify all items' do
      it 'updates the total druid count, attempts to update the APO for each druid, and commits to solr' do
        pids.each do |pid|
          expect(subject).to receive(:set_governing_apo_and_index_safely).with(pid, buffer)
        end
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq pids.length
      end

      it 'logs info about progress' do
        allow(subject).to receive(:set_governing_apo_and_index_safely)

        subject.perform(bulk_action.id, params)

        bulk_action_id = bulk_action.id
        expect(buffer.string).to include "Starting SetGoverningApoJob for BulkAction #{bulk_action_id}"
        pids.each do |pid|
          expect(buffer.string).to include "SetGoverningApoJob: Starting update for #{pid} (bulk_action.id=#{bulk_action_id})"
          expect(buffer.string).to include "SetGoverningApoJob: Finished update for #{pid} (bulk_action.id=#{bulk_action_id})"
        end
        expect(buffer.string).to include "Finished SetGoverningApoJob for BulkAction #{bulk_action_id}"
      end
    end

    context 'when the user lacks the ability to manage an item and items are not found' do
      let(:cocina1) do
        Cocina::Models.build({
                               'label' => 'My Item',
                               'version' => 2,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => pids[0],
                               'description' => {
                                 'title' => [{ 'value' => 'My Item' }],
                                 'purl' => "https://purl.stanford.edu/#{pids[0].delete_prefix('druid:')}"
                               },
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
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => pids[2],
                               'description' => {
                                 'title' => [{ 'value' => 'My Item' }],
                                 'purl' => "https://purl.stanford.edu/#{pids[2].delete_prefix('druid:')}"
                               },
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
        allow(subject.ability).to receive(:can?).and_return(true, false)
      end

      # it might be cleaner to break the testing here into smaller cases for #set_governing_apo_and_index_safely,
      # assuming one is inclined to test private methods, but it also seemed reasonable to do a slightly more end-to-end
      # test of #perform, to prove that common failure cases for individual objects wouldn't fail the whole run.
      it 'increments the failure and success counts and logs status of each update' do
        subject.perform(bulk_action.id, params)
        expect(state_service).to have_received(:allows_modification?)
        expect(object_client1).to have_received(:update).with(params: Cocina::Models::DRO)

        expect(bulk_action.druid_count_success).to eq 1
        expect(bulk_action.druid_count_fail).to eq 2

        bulk_action_id = bulk_action.id
        expect(buffer.string).to include "SetGoverningApoJob: Successfully updated #{pids[0]} (bulk_action.id=#{bulk_action_id})"
        expect(buffer.string).to include "SetGoverningApoJob: Unexpected error for #{pids[1]} (bulk_action.id=#{bulk_action_id}): " \
                                         'Dor::Services::Client::NotFoundResponse'
        expect(buffer.string).to include "SetGoverningApoJob: Unexpected error for #{pids[2]} (bulk_action.id=#{bulk_action_id}): " \
                                         'user not authorized to move druid:dd111ff2222 to druid:bc111bb2222'
      end
    end
  end
end
