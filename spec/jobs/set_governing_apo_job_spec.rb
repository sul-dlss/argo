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
    let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222', 'druid:dd111ff2222'] }
    let(:params) do
      {
        druids: druids,
        new_apo_id: new_apo_id,
        webauth: webauth
      }.with_indifferent_access
    end

    let(:buffer) { StringIO.new }
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    before do
      allow(BulkJobLog).to receive(:open).and_yield(buffer)
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'when the user can modify all items' do
      it 'logs info about progress' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(buffer.string).to include "Starting SetGoverningApoJob for BulkAction #{bulk_action.id}"
        expect(buffer.string).to include "Finished SetGoverningApoJob for BulkAction #{bulk_action.id}"
      end
    end

    context 'when the user lacks the ability to manage an item and items are not found' do
      let(:cocina1) do
        build(:dro, id: druids[0])
      end
      let(:cocina3) do
        build(:dro, id: druids[2])
      end

      let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, update: true) }
      let(:object_client3) { instance_double(Dor::Services::Client::Object, find: cocina3) }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
        allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_raise(Dor::Services::Client::NotFoundResponse)
        allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
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

        expect(buffer.string).to include "Governing APO updated for #{druids[0]}"
        expect(buffer.string).to include "Set governing APO failed Dor::Services::Client::NotFoundResponse Dor::Services::Client::NotFoundResponse for #{druids[1]}"
        expect(buffer.string).to include 'user not authorized to move item to druid:bc111bb2222 for druid:dd111ff2222'
      end
    end
  end
end
