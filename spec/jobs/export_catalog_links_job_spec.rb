# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportCatalogLinksJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:hj185xx2222' }

  let(:bulk_action) { create(:bulk_action) }
  let(:csv_path) { File.join(bulk_action.output_directory, Settings.export_catalog_links_job.csv_filename) }
  let(:log) { StringIO.new }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find_lite: cocina_object) }
  let(:cocina_object) { build(:dro, id: druid).new(identification: { catalogLinks: [link], barcode: '36105010101010', sourceId: 'sul:123' }) }
  let(:link) do
    Cocina::Models::FolioCatalogLink.new(catalog: 'folio',
                                         catalogRecordId: 'in1234',
                                         refresh: true,
                                         partLabel: 'Part 1',
                                         sortKey: '1')
  end

  before do
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
  end

  after do
    FileUtils.rm_f(csv_path)
  end

  it 'performs the job' do
    job.perform_now

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)

    expect(log.string).to include "Exporting FOLIO instance HRIDs and barcodes for #{druid}"

    expect(File).to exist(csv_path)

    csv = CSV.read(csv_path, headers: true)
    expect(csv.headers).to eq %w[druid folio_instance_hrid refresh part_label sort_key barcode]
    expect(csv[0].to_h.values).to eq [druid, 'in1234', 'true', 'Part 1', '1', '36105010101010']
  end
end
