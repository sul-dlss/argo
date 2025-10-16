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
  let(:ability) { instance_double(Ability, can?: true) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Ability).to receive(:new).and_return(ability)
  end

  describe '#perform' do
    let(:druids) { ['druid:bb111cc2222', 'druid:cc111dd2222', 'druid:dd111ff2222'] }
    let(:params) do
      {
        druids:,
        new_apo_id:,
        webauth:
      }.with_indifferent_access
    end

    let(:log) { StringIO.new }

    before do
      allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
      allow(VersionService).to receive(:open?).and_return(true)
    end

    context 'when the user can modify all items' do
      it 'logs info about progress' do
        subject.perform(bulk_action.id, params)
        expect(bulk_action.druid_count_total).to eq druids.length
        expect(log.string).to include "Starting SetGoverningApoJob for BulkAction #{bulk_action.id}"
        expect(log.string).to include "Finished SetGoverningApoJob for BulkAction #{bulk_action.id}"
      end
    end

    context 'when the user lacks the ability to manage an item and items are not found' do
      let(:cocina1) do
        build(:dro_with_metadata, id: druids[0])
      end
      let(:cocina3) do
        build(:dro_with_metadata, id: druids[2])
      end

      let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina1, update: true) }
      let(:object_client3) { instance_double(Dor::Services::Client::Object, find: cocina3) }

      before do
        allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
        allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_raise(Dor::Services::Client::NotFoundResponse)
        allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
        allow(ability).to receive(:can?).and_return(true, false)
      end

      # it might be cleaner to break the testing here into smaller cases for #set_governing_apo_and_index_safely,
      # assuming one is inclined to test private methods, but it also seemed reasonable to do a slightly more end-to-end
      # test of #perform, to prove that common failure cases for individual objects wouldn't fail the whole run.
      it 'increments the failure and success counts and logs status of each update' do
        subject.perform(bulk_action.id, params)
        expect(VersionService).to have_received(:open?)
        expect(object_client1).to have_received(:update).with(params: Cocina::Models::DROWithMetadata)

        expect(bulk_action.druid_count_success).to eq 1
        expect(bulk_action.druid_count_fail).to eq 2

        expect(log.string).to include "Governing APO updated for #{druids[0]}"
        expect(log.string).to include 'Failed Dor::Services::Client::NotFoundResponse Dor::Services::Client::NotFoundResponse for druid:cc111dd2222'
        expect(log.string).to include 'User not authorized to move item to druid:bc111bb2222 for druid:dd111ff2222'
      end
    end
  end
end
