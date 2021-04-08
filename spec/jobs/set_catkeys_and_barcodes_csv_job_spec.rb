# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCatkeysAndBarcodesCsvJob do
  let(:bulk_action_no_process_callback) do
    bulk_action = build(
      :bulk_action,
      action_type: 'SetCatkeysAndBarcodesCsvJob'
    )
    bulk_action.save
    bulk_action
  end

  let(:pids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:catkeys) { ['12345', '', '44444'] }
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }
  let(:item1) do
    Cocina::Models.build(
      'label' => 'My Item1',
      'version' => 2,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[0],
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {
        barcode: '36105014757519',
        catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12346' }]
      }
    )
  end
  let(:item2) do
    Cocina::Models.build(
      'label' => 'My Item2',
      'version' => 3,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[1],
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {
        barcode: '36105014757510',
        catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12347' }]
      }
    )
  end
  let(:item3) do
    Cocina::Models.build(
      'label' => 'My Item3',
      'version' => 3,
      'type' => Cocina::Models::Vocab.object,
      'externalIdentifier' => pids[2],
      'access' => {
        'access' => 'world'
      },
      'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
      'structural' => {},
      'identification' => {}
    )
  end

  let(:csv_file) do
    [
      'Druid,Barcode,Catkey',
      [pids[0], barcodes[0], catkeys[0]].join(','),
      [pids[1], barcodes[1], catkeys[1]].join(','),
      [pids[2], barcodes[2], catkeys[2]].join(',')
    ].join("\n")
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
    allow(Dor::Services::Client).to receive(:object).with(pids[0]).and_return(object_client1)
  end

  describe '#perform' do
    it 'attempts to update the catkey/barcode for each druid with correct corresponding catkey/barcode' do
      params =
        {
          pids: pids,
          set_catkeys_and_barcodes: {
            catkeys: nil,
            barcodes: barcodes.join("\n"),
            use_catkeys_option: '1',
            use_barcodes_option: '1'
          },
          csv_file: csv_file
        }
      expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
      expect(subject).to receive(:update_catkey_and_barcode).with(pids[0], ItemChangeSet.new(barcode: barcodes[0], catkey: catkeys[0]), buffer)
      expect(subject).to receive(:update_catkey_and_barcode).with(pids[1], ItemChangeSet.new(barcode: nil, catkey: nil), buffer)
      expect(subject).to receive(:update_catkey_and_barcode).with(pids[2], ItemChangeSet.new(barcode: barcodes[2], catkey: catkeys[2]), buffer)
      subject.perform(bulk_action_no_process_callback.id, params)
      expect(bulk_action_no_process_callback.druid_count_total).to eq pids.length
    end
  end
end
