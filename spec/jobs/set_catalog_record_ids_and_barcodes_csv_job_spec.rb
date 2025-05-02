# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCatalogRecordIdsAndBarcodesCsvJob do
  let(:bulk_action) do
    create(:bulk_action, action_type: 'SetCatalogRecordIdsAndBarcodesCsvJob')
  end

  let(:authorized_to_update) { true }
  let(:open_version) { true }
  let(:druids) { %w[druid:bb111cc2222 druid:cc111dd2222 druid:dd111ff2222] }
  let(:catalog_record_ids) { ["#{catalog_record_id_prefix}12345", '', "#{catalog_record_id_prefix}44444"] } # 'a12345,a66233'
  let(:refresh) { ['true', '', 'false'] }
  let(:barcodes) { ['36105014757517', '', '36105014757518'] }
  let(:buffer) { StringIO.new }
  let(:catalog_record_id_column) { CatalogRecordId.csv_header }
  let(:catalog_record_id_prefix) { 'in' }

  # Replace catalog_record_id on this item
  let(:item1) do
    build(:dro_with_metadata, id: druids[0], barcode: '36105014757519', folio_instance_hrids: ['a12346'])
  end

  # Remove catalog_record_id on this item
  let(:item2) do
    build(:dro_with_metadata, id: druids[1], barcode: '36105014757510', folio_instance_hrids: ['a12347'])
  end

  # Add catalog_record_id on this item
  let(:item3) do
    build(:dro_with_metadata, id: druids[2])
  end

  let(:csv) do
    [
      "druid,barcode,#{catalog_record_id_column},#{catalog_record_id_column},refresh",
      [druids[0], barcodes[0], catalog_record_ids[0], "#{catalog_record_id_prefix}55555", refresh[0]].join(','),
      [druids[1], barcodes[1], catalog_record_ids[1], '', refresh[1]].join(','),
      [druids[2], barcodes[2], catalog_record_ids[2], '', refresh[2]].join(',')
    ].join("\n")
  end

  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: item1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: item2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find: item3) }

  before do
    allow(subject).to receive(:bulk_action).and_return(bulk_action)
    allow(subject).to receive(:with_bulk_action_log).and_yield(buffer)
    allow(Dor::Services::Client).to receive(:object).with(druids[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druids[1]).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druids[2]).and_return(object_client3)
    allow(VersionService).to receive(:open?).and_return(open_version)
    allow(subject.ability).to receive(:can?).and_return(authorized_to_update)
    allow_any_instance_of(ItemChangeSet).to receive(:save) # rubocop:disable RSpec/AnyInstance
  end

  it 'attempts to update the catalog_record_id/barcode for each druid with correct corresponding catalog_record_id/barcode' do
    subject.perform(bulk_action.id, { csv_file: StringIO.new(csv) })
    expect(bulk_action.druid_count_total).to eq druids.length
    expect(bulk_action.druid_count_fail).to eq 0
  end

  context 'with invalid barcode and catalog_record_ids' do
    let(:csv) do
      [
        "druid,barcode,#{catalog_record_id_column},#{catalog_record_id_column},refresh",
        [druids[0], 'superbad', catalog_record_ids[0], "#{catalog_record_id_prefix}55555", refresh[0]].join(','),
        [druids[1], barcodes[1], 'trash', '', refresh[1]].join(','),
        [druids[2], barcodes[2], catalog_record_ids[2], '', refresh[2]].join(',')
      ].join("\n")
    end

    it 'only attempts to update the catalog_record_id/barcode for the one druid with valid barcode/catalog_record_id' do
      subject.perform(bulk_action.id, { csv_file: StringIO.new(csv) })
      expect(bulk_action.druid_count_total).to eq druids.length
      expect(bulk_action.druid_count_fail).to eq 2
    end
  end

  context 'when not authorized' do
    let(:authorized_to_update) { false }

    it 'logs and returns' do
      subject.perform(bulk_action.id, { csv_file: StringIO.new(csv) })
      expect(bulk_action.druid_count_total).to eq druids.length
      expect(bulk_action.druid_count_fail).to eq 3
      expect(buffer.string).to include('Not authorized')
    end
  end

  context 'when error' do
    before do
      allow(VersionService).to receive(:open?).and_raise('Oops')
    end

    it 'logs' do
      subject.perform(bulk_action.id, { csv_file: StringIO.new(csv) })
      expect(bulk_action.druid_count_total).to eq druids.length
      expect(bulk_action.druid_count_fail).to eq 3
      expect(buffer.string).to include('Set Catalog Record IDs and Barcodes failed RuntimeError Oops for druid:bb111cc2222')
    end
  end
end
