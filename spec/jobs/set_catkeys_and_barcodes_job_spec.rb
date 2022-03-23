# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCatkeysAndBarcodesJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'SetCatkeysAndBarcodesJob'
    )
    bulk_action.save
    bulk_action
  end

  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:catkeys) { ['12345,66233', '', '44444'] }
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }
  let(:item1) do
    build(:item, id: druids[0], barcode: '36105014757519', catkeys: ['12346'])
  end
  let(:item2) do
    build(:item, id: druids[1], barcode: '36105014757510', catkeys: ['12347'])
  end
  let(:item3) do
    build(:item, id: druids[2])
  end

  let(:change_set1) { instance_double(ItemChangeSet, validate: true, model: item1, changed?: true) }
  let(:change_set2) { instance_double(ItemChangeSet, validate: true, model: item2, changed?: false) }
  let(:change_set3) { instance_double(ItemChangeSet, validate: true, model: item3, changed?: true) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
  end

  describe '#perform' do
    before do
      allow(Repository).to receive(:find).with(druids[0]).and_return(item1)
      allow(Repository).to receive(:find).with(druids[1]).and_return(item2)
      allow(Repository).to receive(:find).with(druids[2]).and_return(item3)
    end

    context 'when catkey and barcode selected' do
      before do
        allow(ItemChangeSet).to receive(:new).and_return(change_set1, change_set2, change_set3)
        allow(BulkJobLog).to receive(:open).and_yield(buffer)
      end

      let(:params) do
        {
          druids: druids,
          catkeys: catkeys.join("\n"),
          barcodes: barcodes.join("\n"),
          use_catkeys_option: '1',
          use_barcodes_option: '1'
        }.with_indifferent_access
      end

      it 'attempts to update the catkey/barcode for each druid with correct corresponding catkey/barcode' do
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).to receive(:update_catkey_and_barcode).with(change_set1, buffer)
        expect(subject).not_to receive(:update_catkey_and_barcode).with(change_set2, buffer)
        expect(subject).to receive(:update_catkey_and_barcode).with(change_set3, buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
        expect(change_set1).to have_received(:validate).with(barcode: barcodes[0], catkeys: %w[12345 66233])
        expect(change_set2).to have_received(:validate).with(barcode: nil, catkeys: [])
        expect(change_set3).to have_received(:validate).with(barcode: barcodes[2], catkeys: [catkeys[2]])
      end
    end

    context 'when catkey and barcode not selected' do
      let(:params) do
        {
          druids: druids,
          catkeys: catkeys.join("\n"),
          barcodes: barcodes.join("\n"),
          use_catkeys_option: '0',
          use_barcodes_option: '0'
        }.with_indifferent_access
      end

      it 'does not attempts to update the catkey/barcode for each druid' do
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).not_to receive(:update_catkey_and_barcode)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
      end
    end
  end

  describe '#update_catkey_and_barcode' do
    let(:druid) { druids[0] }
    let(:catkeys_arg) { [catkeys[0]] }
    let(:barcode) { barcodes[0] }
    let(:client) { double(Dor::Services::Client) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }
    let(:previous_version) do
      build(:dro, id: druids[0], version: 3).new(identification: {
                                                   barcode: '36105014757519',
                                                   catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12346' }],
                                                   sourceId: 'sul:1234'
                                                 })
    end

    let(:updated_model) do
      previous_version.new(
        {
          identification: {
            barcode: barcode,
            catalogLinks: [
              { catalog: 'previous symphony', catalogRecordId: '12346' },
              { catalog: 'symphony', catalogRecordId: catkeys[0] }
            ],
            sourceId: 'sul:1234'
          }
        }
      )
    end

    let(:change_set) do
      ItemChangeSet.new(Item.new(previous_version)).tap do |change_set|
        change_set.validate(catkeys: catkeys_arg, barcode: barcode)
      end
    end

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(StateService).to receive(:new).and_return(state_service)
      allow(subject.ability).to receive(:can?).and_return(true)
    end

    context 'when not authorized' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      before do
        allow(subject.ability).to receive(:can?).and_return(false)
      end

      it 'logs and returns' do
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).not_to have_received(:update)
        expect(buffer.string).to include('Not authorized')
      end
    end

    context 'when error' do
      let(:state_service) { instance_double(StateService) }

      before do
        allow(state_service).to receive(:allows_modification?).and_raise('oops')
      end

      it 'logs' do
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).not_to have_received(:update)
        expect(buffer.string).to include('Catkey/barcode failed')
      end
    end

    context 'when modification is not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'updates catkey and barcode and versions objects' do
        expect(subject).to receive(:open_new_version).with(druid, 3, "Catkey updated to #{catkeys[0]}. Barcode updated to #{barcode}.")
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end

    context 'when modification is allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: true) }

      it 'updates catkey and barcode and does not version objects if not needed' do
        expect(subject).not_to receive(:open_new_version).with(druid, 3, "Catkey updated to #{catkeys[0]}. Barcode updated to #{barcode}.")
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end

    context 'when catkeys are empty and barcode is nil' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }
      let(:catkeys_arg) { [] }
      let(:barcode) { nil }

      let(:updated_model) do
        previous_version.new(
          {
            identification: {
              barcode: nil,
              catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: '12346' }],
              sourceId: 'sul:1234'
            }
          }
        )
      end

      it 'removes catkey and barcode' do
        expect(subject).to receive(:open_new_version).with(druid, 3, 'Catkey removed. Barcode removed.')
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end
  end
end
