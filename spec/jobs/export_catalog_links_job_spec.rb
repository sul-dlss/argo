# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportCatalogLinksJob do
  subject(:job) { described_class.new }

  let(:bulk_action) { create(:bulk_action, action_type: 'ExportCatalogLinksJob') }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.export_catalog_links_job.csv_filename) }
  let(:log) { StringIO.new }
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find_lite: cocina_object1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find_lite: cocina_object2) }
  let(:object_client3) { instance_double(Dor::Services::Client::Object, find_lite: cocina_object3) }
  let(:druid1) { 'druid:hj185xx2222' }
  let(:druid2) { 'druid:kv840xx0000' }
  let(:druid3) { 'druid:cd123cc1111' }
  let(:cocina_object1) { build(:dro, id: druid1).new(identification: ident1) }
  let(:cocina_object2) { build(:dro, id: druid2).new(identification: ident2) }
  let(:cocina_object3) { build(:dro, id: druid3).new(identification: ident3) }
  let(:ident1) { Cocina::Models::Identification.new(catalogLinks: [link1], barcode: '36105010101010', sourceId: 'sul:123') }
  let(:ident2) { Cocina::Models::Identification.new(catalogLinks: [link2], sourceId: 'sul:234') }
  let(:ident3) { Cocina::Models::Identification.new(barcode: '36105010101011', sourceId: 'sul:345') }
  let(:link1) do
    Cocina::Models::FolioCatalogLink.new(catalog: 'folio',
                                         catalogRecordId: 'in1234',
                                         refresh: true,
                                         partLabel: 'Part 1',
                                         sortKey: '1')
  end
  let(:link2) do
    Cocina::Models::FolioCatalogLink.new(catalog: 'folio',
                                         catalogRecordId: 'in5678',
                                         refresh: false,
                                         partLabel: 'Part 2')
  end

  before do
    allow(job).to receive(:bulk_action).and_return(bulk_action)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Dor::Services::Client).to receive(:object).with(druid1).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid2).and_return(object_client2)
    allow(Dor::Services::Client).to receive(:object).with(druid3).and_return(object_client3)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  describe '#perform_now' do
    let(:groups) { [] }
    let(:user) { instance_double(User, to_s: 'a_user') }

    context 'when happy path' do
      before do
        job.perform(bulk_action.id,
                    druids: [druid1, druid2, druid3],
                    groups:,
                    user:)
      end

      it 'records zero failures and all successes' do
        expect(bulk_action.druid_count_total).to eq(3)
        expect(bulk_action.druid_count_success).to eq(3)
        expect(bulk_action.druid_count_fail).to eq(0)
      end

      it 'logs messages for each druid in the list' do
        expect(log.string).to include "Exporting FOLIO instance HRIDs and barcodes for #{druid1}"
        expect(log.string).to include "Exporting FOLIO instance HRIDs and barcodes for #{druid2}"
        expect(log.string).to include "Exporting FOLIO instance HRIDs and barcodes for #{druid3}"
        expect(log.string).not_to include 'Unexpected error'
      end

      it 'writes a CSV file' do
        expect(File).to exist(csv_path)

        csv = CSV.read(csv_path, headers: true)
        expect(csv.headers).to eq %w[druid folio_instance_hrid refresh part_label sort_key barcode]
        expect(csv[0].to_h.values).to eq [druid1, 'in1234', 'true', 'Part 1', '1', '36105010101010']
        expect(csv[1].to_h.values).to eq [druid2, 'in5678', 'false', 'Part 2', nil, nil]
        expect(csv[2].to_h.values).to eq [druid3, nil, nil, nil, nil, '36105010101011']
      end
    end

    context 'when an exception is raised' do
      before do
        allow(object_client1).to receive(:find_lite).and_raise(StandardError, 'ruh roh')
        job.perform(bulk_action.id,
                    druids: [druid1],
                    groups:,
                    user:)
      end

      it 'records all failures and zero successes' do
        expect(bulk_action.druid_count_total).to eq(1)
        expect(bulk_action.druid_count_success).to eq(0)
        expect(bulk_action.druid_count_fail).to eq(1)
      end

      it 'logs messages for each druid in the list' do
        expect(log.string).to include 'Failed StandardError ruh roh for druid:hj185xx2222'
      end

      it 'writes a CSV file' do
        expect(File).to exist(csv_path)
        csv = CSV.read(csv_path, headers: true)
        expect(csv.headers).to eq %w[druid folio_instance_hrid refresh part_label sort_key barcode]
      end
    end
  end
end
