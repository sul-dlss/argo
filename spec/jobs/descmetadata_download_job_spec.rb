# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DescmetadataDownloadJob do
  subject(:job) { described_class.new(bulk_action.id, druids: [druid]) }

  let(:druid) { 'druid:hj185xx2222' }
  let(:bulk_action) { create(:bulk_action) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO) }

  let(:job_item) do
    described_class::DescmetadataDownloadJobItem.new(druid: druid, index: 0, job: job).tap do |job_item|
      allow(job_item).to receive_messages(check_read_ability?: true, cocina_object: cocina_object)
    end
  end

  let(:output_directory) { bulk_action.output_directory }
  let(:output_zip_filename) { File.join(output_directory, Settings.bulk_metadata.zip) }

  let(:mods_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xlink="http://www.w3.org/1999/xlink" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
        <titleInfo>
          <title>Object Label for Biryani Spice Mix Pine Nut</title>
        </titleInfo>
      </mods>
    XML
  end

  before do
    allow(described_class::DescmetadataDownloadJobItem).to receive(:new).and_return(job_item)
    allow(PurlFetcher::Client::Mods).to receive(:create).and_return(mods_xml)
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  it 'performs the job' do
    job.perform_now

    expect(File).to exist(output_zip_filename)
    Zip::File.open(output_zip_filename) do |open_file|
      expect(open_file.glob('*').map(&:name).sort).to eq ["#{druid}.xml"]
    end

    expect(bulk_action.reload.druid_count_total).to eq(1)
    expect(bulk_action.druid_count_success).to eq(1)
    expect(bulk_action.druid_count_fail).to eq(0)
  end

  context 'when the user lacks read permission' do
    before do
      allow(job_item).to receive(:check_read_ability?).and_return(false)
    end

    it 'does not add the metadata to the zip file' do
      job.perform_now

      expect(File).to exist(output_zip_filename)
      Zip::File.open(output_zip_filename) do |open_file|
        expect(open_file.glob('*').map(&:name)).to be_empty
      end
    end
  end
end
