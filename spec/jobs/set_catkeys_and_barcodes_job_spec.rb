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

  let(:pids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:catkeys) { ['12345', '', '44444'] }
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }
  let(:item1) do
    Cocina::Models.build({
                           'label' => 'My Item1',
                           'version' => 2,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => pids[0],
                           'description' => {
                             'title' => [{ 'value' => 'My Item1' }],
                             'purl' => "https://purl.stanford.edu/#{pids[0].delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {
                             barcode: '36105014757519',
                             catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12346' }]
                           }
                         })
  end
  let(:item2) do
    Cocina::Models.build({
                           'label' => 'My Item2',
                           'version' => 3,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => pids[1],
                           'description' => {
                             'title' => [{ 'value' => 'My Item2' }],
                             'purl' => "https://purl.stanford.edu/#{pids[1].delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {
                             barcode: '36105014757510',
                             catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12347' }]
                           }
                         })
  end
  let(:item3) do
    Cocina::Models.build({
                           'label' => 'My Item3',
                           'version' => 3,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => pids[2],
                           'description' => {
                             'title' => [{ 'value' => 'My Item3' }],
                             'purl' => "https://purl.stanford.edu/#{pids[2].delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }

  let(:change_set1) { instance_double(ItemChangeSet, validate: true, model: item1, changed?: true) }
  let(:change_set2) { instance_double(ItemChangeSet, validate: true, model: item2, changed?: false) }
  let(:change_set3) { instance_double(ItemChangeSet, validate: true, model: item3, changed?: true) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
  end

  describe '#perform' do
    before do
      allow(Dor::Services::Client).to receive(:object).with(pids[1]).and_return(object_client2)
      allow(Dor::Services::Client).to receive(:object).with(pids[2]).and_return(object_client3)
    end

    context 'when catkey and barcode selected' do
      before do
        allow(ItemChangeSet).to receive(:new).and_return(change_set1, change_set2, change_set3)
      end

      it 'attempts to update the catkey/barcode for each druid with correct corresponding catkey/barcode' do
        params =
          {
            pids: pids,
            set_catkeys_and_barcodes: {
              catkeys: catkeys.join("\n"),
              barcodes: barcodes.join("\n"),
              use_catkeys_option: '1',
              use_barcodes_option: '1'
            }
          }
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).to receive(:update_catkey_and_barcode).with(change_set1, buffer)
        expect(subject).not_to receive(:update_catkey_and_barcode).with(change_set2, buffer)
        expect(subject).to receive(:update_catkey_and_barcode).with(change_set3, buffer)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
        expect(change_set1).to have_received(:validate).with(barcode: barcodes[0], catkey: catkeys[0])
        expect(change_set2).to have_received(:validate).with(barcode: nil, catkey: nil)
        expect(change_set3).to have_received(:validate).with(barcode: barcodes[2], catkey: catkeys[2])
      end
    end

    context 'when catkey and barcode not selected' do
      it 'does not attempts to update the catkey/barcode for each druid' do
        params =
          {
            pids: pids,
            set_catkeys_and_barcodes: {
              catkeys: catkeys.join("\n"),
              barcodes: barcodes.join("\n"),
              use_catkeys_option: '0',
              use_barcodes_option: '0'
            }
          }
        expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
        expect(subject).not_to receive(:update_catkey_and_barcode)
        subject.perform(bulk_action_no_process_callback.id, params)
        expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
      end
    end
  end

  describe '#update_catkey_and_barcode' do
    let(:pid) { pids[0] }
    let(:catkey) { catkeys[0] }
    let(:barcode) { barcodes[0] }
    let(:client) { double(Dor::Services::Client) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: item1, update: true) }
    let(:item1) do
      Cocina::Models.build({
                             'label' => 'My Item',
                             'version' => 3,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pids[0],
                             'description' => {
                               'title' => [{ 'value' => 'My Item1' }],
                               'purl' => "https://purl.stanford.edu/#{pids[0].delete_prefix('druid:')}"
                             },
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {
                               barcode: '36105014757519',
                               catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12346' }]
                             }
                           })
    end

    let(:updated_model) do
      item1.new(
        {
          'identification' => {
            'barcode' => barcode,
            'catalogLinks' => [
              { catalog: 'previous symphony', catalogRecordId: '12346' },
              { catalog: 'symphony', catalogRecordId: catkey }
            ]
          }
        }
      )
    end

    let(:change_set) do
      ItemChangeSet.new(item1).tap do |change_set|
        change_set.validate(catkey: catkey, barcode: barcode)
      end
    end

    before do
      allow(Dor::Services::Client).to receive(:object).with(pid).and_return(object_client)
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
        expect(subject).to receive(:open_new_version).with(pid, 3, "Catkey updated to #{catkey}. Barcode updated to #{barcode}.")
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end

    context 'when modification is allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: true) }

      it 'updates catkey and barcode and does not version objects if not needed' do
        expect(subject).not_to receive(:open_new_version).with(pid, 3, "Catkey updated to #{catkey}. Barcode updated to #{barcode}.")
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end

    context 'when catkey and barcode is nil' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }
      let(:catkey) { nil }
      let(:barcode) { nil }

      let(:updated_model) do
        item1.new(
          {
            identification: {
              barcode: nil,
              catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: '12346' }]
            }
          }
        )
      end

      it 'removes catkey and barcode' do
        expect(subject).to receive(:open_new_version).with(pid, 3, 'Catkey removed. Barcode removed.')
        subject.send(:update_catkey_and_barcode, change_set, buffer)
        expect(object_client).to have_received(:update)
          .with(params: updated_model)
      end
    end
  end
end
