# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe DescmetadataDownloadJob do
  let(:download_job) { described_class.new(bulk_action.id) }
  let(:bulk_action) do
    create(:bulk_action,
           action_type: 'DescmetadataDownloadJob',
           log_name: 'foo.txt')
  end
  let(:output_directory) { bulk_action.output_directory }
  let(:output_zip_filename) { File.join(output_directory, Settings.bulk_metadata.zip) }
  let(:druid_list) { ['druid:hj185xx2222', 'druid:kv840xx0000'] }
  let(:dl_job_params) do
    { druids: druid_list }
  end
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina_object1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina_object2) }
  let(:cocina_object1) { build(:dro, id: druid_list.first) }
  let(:cocina_object2) { build(:dro, id: druid_list.last) }
  let(:log) { instance_double(File, puts: nil, close: true) }
  let(:mods_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <mods xmlns="http://www.loc.gov/mods/v3" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xlink="http://www.w3.org/1999/xlink" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
        <titleInfo>
          <title>Object Label for Biryani Spice Mix Pine Nut</title>
        </titleInfo>
        <location>
          <url usage="primary display">https://sul-purl-stage.stanford.edu/wp220vs6582</url>
        </location>
        <relatedItem type="host">
          <titleInfo>
            <title>David Rumsey Map Collection at Stanford University Libraries</title>
          </titleInfo>
          <location>
            <url>https://sul-purl-stage.stanford.edu/bc778pm9866</url>
          </location>
          <typeOfResource collection="yes"/>
        </relatedItem>
      </mods>
    XML
  end

  let(:ability) { instance_double(Ability) }

  before do
    stub_request(:post, 'https://purl-fetcher.example.edu/v1/mods')
      .to_return(status: 200, body: mods_xml, headers: {})
    allow(Dor::Services::Client).to receive(:object).with(druid_list[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(druid_list[1]).and_return(object_client2)

    allow(Ability).to receive(:new).and_return(ability)
    allow(ability).to receive(:can?).with(:read, cocina_object1).and_return(true)
    allow(ability).to receive(:can?).with(:read, cocina_object2).and_return(true)
    allow_any_instance_of(BulkAction).to receive(:open_log_file).and_return(log) # rubocop:disable RSpec/AnyInstance
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  it 'creates a valid zip file' do
    download_job.perform(bulk_action.id, dl_job_params)
    expect(File).to exist(output_zip_filename)
    Zip::File.open(output_zip_filename) do |open_file|
      expect(open_file.glob('*').map(&:name).sort).to eq ["#{druid_list.first}.xml", "#{druid_list.second}.xml"].sort
    end
  end

  context 'when user lacks permission to view metadata on one of the objects' do
    before do
      allow(ability).to receive(:can?).with(:read, cocina_object1).and_return(true)
      allow(ability).to receive(:can?).with(:read, cocina_object2).and_return(false)
    end

    it 'creates a valid zip file with only the objects for which the user has read authorization' do
      expect(download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

      download_job.perform(bulk_action.id, dl_job_params)

      expect(File).to exist(output_zip_filename)
      Zip::File.open(output_zip_filename) do |open_file|
        expect(open_file.glob('*').map(&:name)).to eq ["#{druid_list.first}.xml"]
      end
      expect(log).to have_received(:puts).with(/Not authorized to read for #{druid_list.second}/)
    end
  end
end
