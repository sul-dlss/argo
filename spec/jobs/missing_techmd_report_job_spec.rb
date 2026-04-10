# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MissingTechmdReportJob do
  include Dry::Monads[:result]

  subject(:job) { described_class.new(bulk_action.id, druids: [druid_missing, druid_present]) }

  let(:druid_missing) { 'druid:bb111cc2222' }
  let(:druid_present) { 'druid:ff333gg4444' }

  let(:output_directory) { bulk_action.output_directory }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'MissingTechmdReportJob',
      log_name: 'tmp/missing_techmd_report_job_log.txt'
    )
  end
  let(:csv_filename) { File.join(output_directory, Settings.missing_techmd_report_job.csv_filename) }

  let(:structural) do
    {
      contains: [
        {
          type: Cocina::Models::FileSetType.image.to_s,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/abc123',
          label: 'Image 1',
          version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file.to_s,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/def456',
                label: 'image.tif',
                filename: 'image.tif',
                size: 1_000_000,
                version: 1,
                hasMimeType: 'image/tiff',
                hasMessageDigests: [],
                access: { view: 'world', download: 'world' },
                administrative: { publish: false, sdrPreserve: true, shelve: false }
              }
            ]
          }
        }
      ]
    }
  end

  let(:cocina_object_missing) { build(:dro, id: druid_missing).new(structural:, access: { view: 'world', download: 'world' }) }
  let(:cocina_object_present) { build(:dro, id: druid_present).new(structural:, access: { view: 'world', download: 'world' }) }

  let(:checksum_response) do
    [{ 'filename' => 'image.tif', 'md5' => 'abc', 'sha1' => 'def', 'sha256' => 'ghi', 'filesize' => '1000000' }]
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  before do
    allow(Repository).to receive(:find).with(druid_missing).and_return(cocina_object_missing)
    allow(Repository).to receive(:find).with(druid_present).and_return(cocina_object_present)
    allow(Preservation::Client.objects).to receive(:checksum).with(druid: druid_missing).and_return(checksum_response)
    allow(Preservation::Client.objects).to receive(:checksum).with(druid: druid_present).and_return(checksum_response)
    allow(TechmdService).to receive(:techmd_for).with(druid: druid_missing).and_return(Success([]))
    allow(TechmdService).to receive(:techmd_for).with(druid: druid_present).and_return(Success([{ 'filename' => 'image.tif' }]))
    allow(job).to receive(:check_view_ability?).and_return(true)
  end

  it 'writes only druids missing techmd to the CSV' do
    job.perform_now

    expect(File.read(csv_filename)).to eq(
      <<~CSV
        druid
        #{druid_missing}
      CSV
    )
    expect(bulk_action.reload.druid_count_total).to eq(2)
    expect(bulk_action.druid_count_success).to eq(2)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when not authorized to view' do
    before do
      allow(job).to receive(:check_view_ability?).and_return(false)
    end

    it 'does not call the techmd service' do
      job.perform_now

      expect(TechmdService).not_to have_received(:techmd_for)
    end
  end

  context 'when the techmd service returns a failure' do
    before do
      allow(TechmdService).to receive(:techmd_for).with(druid: druid_missing)
                                                  .and_return(Failure('unexpected 500'))
    end

    it 'records the failure and does not write to the CSV' do
      job.perform_now

      expect(File.read(csv_filename)).to eq("druid\n")
      expect(bulk_action.reload.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(1)
    end
  end

  context 'when the object has no preserved files in Cocina' do
    let(:structural) { { contains: [] } }

    it 'skips the object and does not check techmd' do
      job.perform_now

      expect(TechmdService).not_to have_received(:techmd_for)
      expect(File.read(csv_filename)).to eq("druid\n")
      expect(bulk_action.reload.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when the object is not found in preservation' do
    before do
      allow(Preservation::Client.objects).to receive(:checksum).with(druid: druid_missing)
                                                               .and_raise(Preservation::Client::NotFoundError)
    end

    it 'skips the object and does not check techmd' do
      job.perform_now

      expect(TechmdService).not_to have_received(:techmd_for).with(druid: druid_missing)
      expect(File.read(csv_filename)).to eq("druid\n")
      expect(bulk_action.reload.druid_count_success).to eq(2)
      expect(bulk_action.druid_count_fail).to eq(0)
    end
  end

  context 'when preservation returns an empty checksum list' do
    before do
      allow(Preservation::Client.objects).to receive(:checksum).with(druid: druid_missing).and_return([])
    end

    it 'skips the object and does not check techmd' do
      job.perform_now

      expect(TechmdService).not_to have_received(:techmd_for).with(druid: druid_missing)
      expect(File.read(csv_filename)).to eq("druid\n")
      expect(bulk_action.reload.druid_count_success).to eq(2)
    end
  end
end
