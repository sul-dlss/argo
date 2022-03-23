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

  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:catkeys) { ['12345', '', '44444'] }
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }
  let(:item1) do
    Cocina::Models.build({
                           'label' => 'My Item1',
                           'version' => 2,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druids[0],
                           'description' => {
                             'title' => [{ 'value' => 'My Item1' }],
                             'purl' => "https://purl.stanford.edu/#{druids[0].delete_prefix('druid:')}"
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
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druids[1],
                           'description' => {
                             'title' => [{ 'value' => 'My Item2' }],
                             'purl' => "https://purl.stanford.edu/#{druids[1].delete_prefix('druid:')}"
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
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druids[2],
                           'description' => {
                             'title' => [{ 'value' => 'My Item3' }],
                             'purl' => "https://purl.stanford.edu/#{druids[2].delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  let(:csv_file) do
    [
      'Druid,Barcode,Catkey',
      [druids[0], barcodes[0], catkeys[0]].join(','),
      [druids[1], barcodes[1], catkeys[1]].join(','),
      [druids[2], barcodes[2], catkeys[2]].join(',')
    ].join("\n")
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action_no_process_callback)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
  end

  describe '#perform' do
    it 'attempts to update the catkey/barcode for each druid with correct corresponding catkey/barcode' do
      params =
        {
          druids: druids,
          set_catkeys_and_barcodes: {
            catkeys: nil,
            barcodes: barcodes.join("\n"),
            use_catkeys_option: '1',
            use_barcodes_option: '1'
          },
          csv_file: csv_file
        }
      expect(subject).to receive(:with_bulk_action_log).and_yield(buffer)
      expect(subject).to receive(:update_catkey_and_barcode).with(ItemChangeSet, buffer).exactly(3).times
      subject.perform(bulk_action_no_process_callback.id, params)
      expect(bulk_action_no_process_callback.druid_count_total).to eq druids.length
    end
  end
end
