# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SetCatalogRecordIdsAndBarcodesCsvJob do
  subject(:job) { described_class.new(bulk_action.id, csv_file: StringIO.new(csv)) }

  let(:druid) { 'druid:bb111cc2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:log) { StringIO.new }
  let(:catalog_record_id_column) { CatalogRecordId.csv_header }

  let(:job_item) do
    described_class::SetCatalogRecordIdsAndBarcodesCsvJobItem.new(druid: druid, index: 2, job: job, row:).tap do |job_item|
      allow(job_item).to receive(:open_new_version_if_needed!)
      allow(job_item).to receive(:close_version_if_needed!)
      allow(job_item).to receive_messages(check_update_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:csv) do
    [
      "druid,barcode,#{catalog_record_id_column},#{catalog_record_id_column},refresh",
      [druid, barcode, catalog_record_id1, catalog_record_id2, refresh].join(',')
    ].join("\n")
  end
  let(:catalog_record_id1) { 'in12345' }
  let(:catalog_record_id2) { 'in55555' }
  let(:barcode) { '36105014757517' }
  let(:refresh) { 'true' }

  let(:row) { CSV.parse(csv, headers: true).first }

  let(:item_change_set) do
    ItemChangeSet.new(dro_cocina_object).tap do |change_set|
      allow(change_set).to receive(:validate).and_call_original
      allow(change_set).to receive(:save).and_return(true)
    end
  end

  let(:dro_cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:cocina_object) { dro_cocina_object }

  before do
    allow(described_class::SetCatalogRecordIdsAndBarcodesCsvJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(ItemChangeSet).to receive(:new).and_return(item_change_set)
  end

  context 'when adding catalog_record_ids and barcodes' do
    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated FOLIO HRID, barcode, or serials metadata')

      expect(ItemChangeSet).to have_received(:new).with(cocina_object).twice
      expect(item_change_set).to have_received(:validate).with({ barcode:, catalog_record_ids: [catalog_record_id1, catalog_record_id2], refresh: true, part_label: nil, sort_key: nil }).twice
      expect(item_change_set).to have_received(:save)
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(log.string).to include("Adding #{CatalogRecordId.label} of in12345, in55555")
      expect(log.string).to include('Adding barcode of 36105014757517')

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when removing catalog_record_ids and barcodes' do
    let(:dro_cocina_object) { build(:dro_with_metadata, id: druid, folio_instance_hrids: %w[in12345 in55555], barcode: '36105014757517') }

    let(:catalog_record_id1) { nil }
    let(:catalog_record_id2) { nil }
    let(:barcode) { nil }
    let(:refresh) { 'false' }

    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated FOLIO HRID, barcode, or serials metadata')

      expect(ItemChangeSet).to have_received(:new).with(cocina_object).twice
      expect(item_change_set).to have_received(:validate).with({ barcode:, catalog_record_ids: [], refresh: false, part_label: nil, sort_key: nil }).twice
      expect(item_change_set).to have_received(:save)
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(log.string).to include("Removing #{CatalogRecordId.label}")
      expect(log.string).to include('Removing barcode')

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when no changes' do
    before do
      allow(item_change_set).to receive(:changed?).and_return(false)
    end

    it 'does not update the object' do
      job.perform_now

      expect(log.string).to include('No changes specified for object')

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end

  context 'when a Collection' do
    let(:collection_cocina_object) { build(:collection_with_metadata, id: druid) }
    let(:cocina_object) { collection_cocina_object }
    let(:barcode) { nil }

    let(:collection_change_set) do
      CollectionChangeSet.new(collection_cocina_object).tap do |change_set|
        allow(change_set).to receive(:validate).and_call_original
        allow(change_set).to receive_messages(save: true, changed?: true)
      end
    end

    before do
      allow(CollectionChangeSet).to receive(:new).and_return(collection_change_set)
    end

    it 'performs the job' do
      job.perform_now

      expect(job_item).to have_received(:check_update_ability?)
      expect(job_item).to have_received(:open_new_version_if_needed!).with(description: 'Updated FOLIO HRID, barcode, or serials metadata')

      expect(CollectionChangeSet).to have_received(:new).with(cocina_object).twice
      expect(collection_change_set).to have_received(:validate).with({ catalog_record_ids: %w[in12345 in55555], refresh: true, part_label: nil, sort_key: nil }).twice
      expect(collection_change_set).to have_received(:save)
      expect(job_item).to have_received(:close_version_if_needed!)

      expect(log.string).to include("Adding #{CatalogRecordId.label} of in12345, in55555")

      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(0)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when the user lacks update ability' do
    before do
      allow(job_item).to receive(:check_update_ability?).and_return(false)
    end

    it 'does not update the catalog_record_id/barcode' do
      job.perform_now

      expect(ItemChangeSet).not_to have_received(:new)
    end
  end
end
