# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCatkeysAndBarcodesCsvJob do
  let(:bulk_action) do
    create(:bulk_action, action_type: 'SetCatkeysAndBarcodesCsvJob')
  end

  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:catkeys) { ['12345', '', '44444'] }
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }

  # Replace catkey on this item
  let(:item1) do
    build(:dro, id: druids[0], barcode: '36105014757519', catkeys: ['12346'])
  end

  # Remove catkey on this item
  let(:item2) do
    build(:dro, id: druids[1], barcode: '36105014757510', catkeys: ['12347'])
  end

  # Add catkey on this item
  let(:item3) do
    build(:dro, id: druids[2])
  end

  let(:csv_file) do
    [
      'Druid,Barcode,Catkey,Catkey',
      [druids[0], barcodes[0], catkeys[0], '55555'].join(','),
      [druids[1], barcodes[1], catkeys[1], ''].join(','),
      [druids[2], barcodes[2], catkeys[2], ''].join(',')
    ].join("\n")
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
  end

  describe '#perform' do
    before do
      allow(subject).to receive(:with_bulk_action_log).and_yield(buffer)
      allow(subject).to receive(:update_catkey_and_barcode)
      subject.perform(bulk_action.id, { csv_file: })
    end

    it 'attempts to update the catkey/barcode for each druid with correct corresponding catkey/barcode' do
      expect(bulk_action.druid_count_total).to eq druids.length
      expect(subject).to have_received(:update_catkey_and_barcode).with(ItemChangeSet, Hash, buffer).exactly(3).times
    end
  end
end
