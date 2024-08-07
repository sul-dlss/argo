# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCatalogRecordIdsAndBarcodesJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'SetCatalogRecordIdsAndBarcodesJob'
    )
    bulk_action.save
    bulk_action
  end

  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222 druid:ff111gg2222] }
  let(:catalog_record_ids) do
    ['a12345,a66233', '', 'a44444', 'a55555']
  end
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }
  let(:item1) do
    build(:dro_with_metadata, id: druids[0], barcode: '36105014757519', folio_instance_hrids: ['a12346'])
  end
  let(:item2) do
    build(:dro_with_metadata, id: druids[1], barcode: '36105014757510', folio_instance_hrids: ['a12347'])
  end
  let(:item3) do
    build(:dro_with_metadata, id: druids[2])
  end
  let(:collection1) do
    build(:collection_with_metadata, id: druids[3])
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }
  let(:object_client4) { instance_double(Dor::Services::Client::Object, find: collection1) }

  let(:change_set1) { instance_double(ItemChangeSet, validate: true, model: item1, changed?: true) }
  let(:change_set2) { instance_double(ItemChangeSet, validate: true, model: item2, changed?: false) }
  let(:change_set3) { instance_double(ItemChangeSet, validate: true, model: item3, changed?: true) }
  let(:change_set4) { instance_double(CollectionChangeSet, validate: true, model: item3, changed?: true) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
  end

  describe '#perform' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
      allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
      allow(Dor::Services::Client).to receive(:object).with(druids[3]).and_return(object_client4)
    end

    context 'when catalog_record_id and barcode selected' do
      before do
        allow(ItemChangeSet).to receive(:new).and_return(change_set1, change_set2, change_set3)
        allow(CollectionChangeSet).to receive(:new).and_return(change_set4)
        allow(BulkJobLog).to receive(:open).and_yield(buffer)
      end

      let(:params) do
        {
          druids:,
          catalog_record_ids: catalog_record_ids.join("\n"),
          barcodes: barcodes.join("\n"),
          use_catalog_record_ids_option: '1',
          use_barcodes_option: '1'
        }.with_indifferent_access
      end

      it 'attempts to update the catalog_record_id/barcode for each druid with correct corresponding catalog_record_id/barcode' do
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).to receive(:update_catalog_record_id_and_barcode).with(change_set1,
                                                                               { catalog_record_ids: catalog_record_ids[0].split(','), barcode: barcodes[0], refresh: true }, buffer)
        expect(subject).not_to receive(:update_catalog_record_id_and_barcode).with(change_set2,
                                                                                   { catalog_record_ids: [], barcode: nil }, buffer)
        expect(subject).to receive(:update_catalog_record_id_and_barcode).with(change_set3,
                                                                               { catalog_record_ids: [catalog_record_ids[2]], barcode: barcodes[2], refresh: true }, buffer)
        expect(subject).to receive(:update_catalog_record_id_and_barcode).with(change_set4,
                                                                               { catalog_record_ids: [catalog_record_ids[3]], refresh: true }, buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
        expect(change_set1).to have_received(:validate).with(barcode: barcodes[0],
                                                             catalog_record_ids: %w[a12345 a66233], refresh: true)
        expect(change_set2).to have_received(:validate).with(barcode: nil, catalog_record_ids: [], refresh: true)
        expect(change_set3).to have_received(:validate).with(barcode: barcodes[2],
                                                             catalog_record_ids: [catalog_record_ids[2]], refresh: true)
        expect(change_set4).to have_received(:validate).with(catalog_record_ids: [catalog_record_ids[3]], refresh: true)
      end
    end

    context 'when catalog_record_id selected but none provided' do
      before do
        allow(ItemChangeSet).to receive(:new).and_return(change_set1, change_set2, change_set3)
        allow(BulkJobLog).to receive(:open).and_yield(buffer)
      end

      let(:params) do
        {
          druids:,
          catalog_record_ids: "\n\n44444", # two blank rows, one row with a catalog_record_id
          barcodes: '',
          use_catalog_record_ids_option: '1',
          use_barcodes_option: '0'
        }.with_indifferent_access
      end

      it 'attempts to update the catalog_record_id for each druid with an empty array and not nil' do
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).to receive(:update_catalog_record_id_and_barcode).with(change_set1, { catalog_record_ids: [], refresh: true }, buffer) # changed to empty
        expect(subject).not_to receive(:update_catalog_record_id_and_barcode).with(change_set2, { catalog_record_ids: [], refresh: true }, buffer) # not changed
        expect(subject).to receive(:update_catalog_record_id_and_barcode).with(change_set3, { catalog_record_ids: ['44444'], refresh: true }, buffer) # changed to a value
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
        expect(change_set1).to have_received(:validate).with(catalog_record_ids: [], refresh: true) # set to empty
        expect(change_set2).to have_received(:validate).with(catalog_record_ids: [], refresh: true) # not changed
        expect(change_set3).to have_received(:validate).with(catalog_record_ids: ['44444'], refresh: true) # changed to a value
      end
    end

    context 'when catalog_record_id and barcode not selected' do
      let(:params) do
        {
          druids:,
          catalog_record_ids: catalog_record_ids.join("\n"),
          barcodes: barcodes.join("\n"),
          use_catalog_record_ids_option: '0',
          use_barcodes_option: '0'
        }.with_indifferent_access
      end

      it 'does not attempts to update the catalog_record_id/barcode for each druid' do
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).not_to receive(:update_catalog_record_id_and_barcode)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
      end
    end
  end

  describe '#update_catalog_record_id_and_barcode' do
    let(:druid) { druids[0] }
    let(:catalog_record_ids_arg) { catalog_record_ids[0].split(',') }
    let(:object_client) { instance_double(Dor::Services::Client::Object, update: true) }
    let(:client) { double(Dor::Services::Client) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
      allow(subject.ability).to receive(:can?).and_return(true)
    end

    context 'when a DRO' do
      let(:barcode) { barcodes[0] }
      let(:previous_version) do
        build(:dro_with_metadata, id: druids[0], version: 3).new(identification: {
                                                                   barcode: '36105014757519',
                                                                   catalogLinks: [{ catalog: 'folio',
                                                                                    catalogRecordId: 'a12346', refresh: true }],
                                                                   sourceId: 'sul:1234'
                                                                 })
      end

      let(:updated_model) do
        previous_version.new(
          {
            identification: {
              barcode:,
              catalogLinks: [
                { catalog: 'previous folio', catalogRecordId: 'a12346', refresh: false },
                { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
                { catalog: 'folio', catalogRecordId: 'a66233', refresh: false }
              ],
              sourceId: 'sul:1234'
            }
          }
        )
      end

      let(:change_set) do
        ItemChangeSet.new(previous_version).tap do |change_set|
          change_set.validate(catalog_record_ids: catalog_record_ids_arg, barcode:)
        end
      end

      context 'when not authorized' do
        before do
          allow(subject.ability).to receive(:can?).and_return(false)
          allow(VersionService).to receive(:open?).and_return(false)
        end

        it 'logs and returns' do
          subject.send(:update_catalog_record_id_and_barcode, change_set,
                       { catalog_record_ids: catalog_record_ids_arg, barcode: }, buffer)
          expect(object_client).not_to have_received(:update)
          expect(buffer.string).to include('Not authorized')
        end
      end

      context 'when error' do
        before do
          allow(VersionService).to receive(:open?).and_raise('oops')
        end

        it 'logs' do
          subject.send(:update_catalog_record_id_and_barcode, change_set,
                       { catalog_record_ids: catalog_record_ids_arg, barcode: }, buffer)
          expect(object_client).not_to have_received(:update)
          expect(buffer.string).to include("#{CatalogRecordId.label}/barcode failed")
        end
      end

      context 'when not open' do
        before do
          allow(VersionService).to receive(:open?).and_return(false)
        end

        it 'updates catalog_record_id and barcode and versions objects' do
          expect(subject).to receive(:open_new_version).with(previous_version,
                                                             "#{CatalogRecordId.label} updated to a12345, a66233. Barcode updated to #{barcode}.").and_return(previous_version)
          subject.send(:update_catalog_record_id_and_barcode, change_set,
                       { catalog_record_ids: catalog_record_ids_arg, barcode:, refresh: true }, buffer)
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
        end
      end

      context 'when open' do
        before do
          allow(VersionService).to receive(:open?).and_return(true)
        end

        it 'updates catalog_record_id and barcode and does not version objects if not needed' do
          expect(subject).not_to receive(:open_new_version).with(previous_version,
                                                                 "#{CatalogRecordId.label} updated to #{catalog_record_ids[0]}. Barcode updated to #{barcode}.")
          subject.send(:update_catalog_record_id_and_barcode, change_set,
                       { catalog_record_ids: catalog_record_ids_arg, barcode:, refresh: true }, buffer)
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
        end
      end

      context 'when catalog_record_ids are empty and barcode is nil' do
        let(:catalog_record_ids_arg) { [] }
        let(:barcode) { nil }
        let(:updated_model) do
          previous_version.new(
            {
              identification: {
                barcode: nil,
                catalogLinks: [{ catalog: 'previous folio', catalogRecordId: 'a12346', refresh: false }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        before do
          allow(VersionService).to receive(:open?).and_return(false)
        end

        it 'removes catalog_record_id and barcode' do
          expect(subject).to receive(:open_new_version).with(previous_version,
                                                             "#{CatalogRecordId.label} removed. Barcode removed.").and_return(previous_version)
          subject.send(:update_catalog_record_id_and_barcode, change_set,
                       { catalog_record_ids: catalog_record_ids_arg, barcode: }, buffer)
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
        end
      end
    end

    context 'when a Collection' do
      context 'when modification is allowed' do
        let(:previous_version) do
          build(:collection_with_metadata, id: druids[0], version: 3).new(identification: {
                                                                            catalogLinks: [{ catalog: 'folio',
                                                                                             catalogRecordId: 'a12346', refresh: true }],
                                                                            sourceId: 'sul:1234'
                                                                          })
        end

        let(:updated_model) do
          previous_version.new(
            {
              identification: {
                catalogLinks: [
                  { catalog: 'previous folio', catalogRecordId: 'a12346', refresh: false },
                  { catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
                  { catalog: 'folio', catalogRecordId: 'a66233', refresh: false }
                ],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        let(:change_set) do
          CollectionChangeSet.new(previous_version).tap do |change_set|
            change_set.validate(catalog_record_ids: catalog_record_ids_arg)
          end
        end

        before do
          allow(VersionService).to receive(:open?).and_return(true)
        end

        it 'updates catalog_record_id and barcode and does not version objects if not needed' do
          expect(subject).not_to receive(:open_new_version).with(previous_version,
                                                                 "#{CatalogRecordId.label} updated to #{catalog_record_ids[0]}.")
          subject.send(:update_catalog_record_id_and_barcode, change_set,
                       { catalog_record_ids: catalog_record_ids_arg, refresh: true }, buffer)
          expect(object_client).to have_received(:update)
            .with(params: updated_model)
        end
      end
    end
  end
end
