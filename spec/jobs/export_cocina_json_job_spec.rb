# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportCocinaJsonJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:hj185xx2222' }
  let(:bulk_action) { create(:bulk_action) }

  let(:jsonl_path) { File.join(bulk_action.output_directory, Settings.export_cocina_json_job.jsonl_filename) }
  let(:gzip_path) { File.join(bulk_action.output_directory, Settings.export_cocina_json_job.gzip_filename) }
  let(:unzipped_path) { File.join(bulk_action.output_directory, 'unzipped_file.jsonl') }

  let(:cocina_object) { build(:dro_with_metadata, id: druid) }
  let(:log) { StringIO.new }

  let(:job_item) do
    described_class::ExportCocinaJsonJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive(:cocina_object).and_return(cocina_object)
    end
  end

  before do
    allow(described_class::ExportCocinaJsonJobItem).to receive(:new).and_return(job_item)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  after do
    FileUtils.rm_f(jsonl_path)
    FileUtils.rm_f(gzip_path)
    FileUtils.rm_f(unzipped_path)
  end

  it 'performs the job' do
    job.perform_now

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)

    expect(File).not_to exist(jsonl_path)

    expect(File).to exist(gzip_path)
    File.write(unzipped_path, ActiveSupport::Gzip.decompress(File.read(gzip_path)))
    expect(File.open(unzipped_path).readlines.size).to eq 1
  end
end
