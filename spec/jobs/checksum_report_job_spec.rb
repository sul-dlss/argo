# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChecksumReportJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:bb111cc2222' }

  let(:output_directory) { bulk_action.output_directory }
  let(:bulk_action) do
    create(
      :bulk_action,
      action_type: 'ChecksumReportJob',
      log_name: 'tmp/checksum_report_job_log.txt'
    )
  end
  let(:csv_response) { "#{druid},checksum1,checksum2\ndruid:456,checksum3,checksum4\n" }
  let(:checksum_response) do
    [{
      'filename' => 'oo000oo0000_img_1.tif',
      'md5' => 'ffc0cc90e4215e0a3d822b04a8eab980',
      'sha1' => 'd2703add746d7b6e2e5f8a73ef7c06b087b3fae5',
      'sha256' => '6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f',
      'filesize' => '4403882'
    },
     {
       'filename' => 'oo000oo0000_img_2.tif',
       'md5' => 'ggc0cc90e4215e0a3d822b04a8eab991',
       'sha1' => 'e3703add746d7b6e2e5f8a73ef7c06b087b3faf6',
       'sha256' => '7c66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527033g',
       'filesize' => '5503893'
     }]
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  before do
    allow(Preservation::Client.objects).to receive(:checksum).with(druid:).and_return(checksum_response)
    allow(job).to receive(:check_view_ability?).and_return(true)
  end

  it 'performs the job' do
    job.perform_now

    expect(File.read(File.join(output_directory, Settings.checksum_report_job.csv_filename))).to eq(
      <<~CSV
        druid,filename,md5,sha1,sha256,size
        #{druid},oo000oo0000_img_1.tif,ffc0cc90e4215e0a3d822b04a8eab980,d2703add746d7b6e2e5f8a73ef7c06b087b3fae5,6b66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527032f,4403882
        #{druid},oo000oo0000_img_2.tif,ggc0cc90e4215e0a3d822b04a8eab991,e3703add746d7b6e2e5f8a73ef7c06b087b3faf6,7c66cc2df50427d03dca8608af20b3fd96d76b67ba41c148901aa1a60527033g,5503893
      CSV
    )
    expect(job).to have_received(:check_view_ability?)

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
    expect(bulk_action.druid_count_success).to eq(1)
  end

  context 'when not authorized to view' do
    before do
      allow(job).to receive(:check_view_ability?).and_return(false)
    end

    it 'does not call the preservation_catalog API and records failure counts' do
      job.perform_now

      expect(Preservation::Client.objects).not_to have_received(:checksum)
    end
  end

  context 'when item is not found in Preservation Catalog' do
    before do
      allow(Preservation::Client.objects).to receive(:checksum).with(druid: druid).and_raise(Preservation::Client::NotFoundError)
    end

    it 'performs the job' do
      job.perform_now

      expect(File.read(File.join(output_directory, Settings.checksum_report_job.csv_filename))).to eq(
        <<~CSV
          druid,filename,md5,sha1,sha256,size
          #{druid},object not found or not fully accessioned
        CSV
      )
      expect(bulk_action.reload.druid_count_total).to eq(1)
      expect(bulk_action.druid_count_fail).to eq(1)
      expect(bulk_action.druid_count_success).to eq(0)
    end
  end
end
