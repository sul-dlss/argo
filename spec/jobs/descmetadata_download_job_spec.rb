# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe DescmetadataDownloadJob, type: :job do
  let(:download_job) { described_class.new(bulk_action.id) }
  let(:bulk_action) do
    create(:bulk_action,
           action_type: 'DescmetadataDownloadJob',
           log_name: 'foo.txt')
  end
  let(:output_directory) { bulk_action.output_directory }
  let(:output_zip_filename) { File.join(output_directory, Settings.bulk_metadata.zip) }
  let(:pid_list) { ['druid:hj185xx2222', 'druid:kv840xx0000'] }
  let(:dl_job_params) do
    { pids: pid_list }
  end
  let(:object_client1) { instance_double(Dor::Services::Client::Object, find: cocina_model1, metadata: metadata_client1) }
  let(:object_client2) { instance_double(Dor::Services::Client::Object, find: cocina_model2, metadata: metadata_client2) }
  let(:metadata_client1) { instance_double(Dor::Services::Client::Metadata, mods: '<mods/>') }
  let(:metadata_client2) { instance_double(Dor::Services::Client::Metadata, mods: '<mods/>') }
  let(:cocina_model1) { instance_double(Cocina::Models::DRO) }
  let(:cocina_model2) { instance_double(Cocina::Models::DRO) }

  before do
    allow(Dor::Services::Client).to receive(:object).with(pid_list[0]).and_return(object_client1)
    allow(Dor::Services::Client).to receive(:object).with(pid_list[1]).and_return(object_client2)
  end

  after do
    FileUtils.rm_rf(output_directory)
  end

  describe '#zip_filename' do
    it 'returns a filename of the correct form' do
      expect(download_job.zip_filename).to eq(output_zip_filename)
    end
  end

  describe 'start_log' do
    let(:log) { double('log', flush: nil) }

    it 'writes the correct information to the log' do
      expect(log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_job_start .*/)
      expect(log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_user .*/)
      expect(log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_input_file .*/)
      expect(log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_note .*/)
      download_job.start_log(log, 'fakeuser', 'fakefile', 'fakenote')
    end

    it 'completes without erring given a nil argument for note, or no arg' do
      allow(log).to receive(:puts)
      expect { download_job.start_log(log, 'fakeuser', 'fakefile', nil) }.not_to raise_error
      expect { download_job.start_log(log, 'fakeuser', 'fakefile')      }.not_to raise_error
    end
  end

  describe 'write_to_zip' do
    it 'writes the given value to the zip file' do
      zip = double('zip_file')
      druid = 'druid:123'
      output_file = double('zip_output_file')
      string_value = 'descMetadata.xml'
      expect(zip).to receive(:get_output_stream).with("#{druid}.xml").and_yield(output_file)
      expect(output_file).to receive(:puts).with(string_value)
      download_job.write_to_zip(string_value, druid, zip)
    end
  end

  describe 'perform' do
    let(:ability) { instance_double(Ability) }
    let(:bulk_action) do
      create(:bulk_action, action_type: 'DescmetadataDownloadJob', log_name: 'foo.txt')
    end

    before do
      allow(Ability).to receive(:new).and_return(ability)
      allow(ability).to receive(:can?).with(:view_metadata, cocina_model1).and_return(true)
      allow(ability).to receive(:can?).with(:view_metadata, cocina_model2).and_return(true)
    end

    after do
      FileUtils.rm_f('foo.txt')
    end

    it 'creates a valid zip file' do
      expect(download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

      download_job.perform(bulk_action.id, dl_job_params)
      expect(File).to be_exist(output_zip_filename)
      Zip::File.open(output_zip_filename) do |open_file|
        expect(open_file.glob('*').map(&:name).sort).to eq ["#{pid_list.first}.xml", "#{pid_list.second}.xml"].sort
      end
    end

    context 'when dor-services-app fails to find the object' do
      let(:log) { double('log', puts: nil, flush: nil) }

      before do
        allow(object_client1).to receive(:find).and_raise(Faraday::TimeoutError)
        allow(object_client2).to receive(:find).and_raise(Faraday::TimeoutError)
        allow(bulk_action).to receive(:increment).with(:druid_count_fail)
        allow(bulk_action).to receive_message_chain(:increment, :save)
        allow(download_job).to receive(:bulk_action).and_return(bulk_action)
        allow(download_job).to receive(:with_bulk_action_log).and_yield(log)
      end

      it 'tries again and logs messages' do
        download_job.perform(bulk_action.id, dl_job_params)

        expect(object_client1).to have_received(:find).exactly(described_class::MAX_TRIES).times
        expect(object_client2).to have_received(:find).exactly(described_class::MAX_TRIES).times
        expect(bulk_action).to have_received(:increment).with(:druid_count_fail).twice
        expect(download_job).to have_received(:bulk_action).at_least(:once)
        expect(File).to be_exist(output_zip_filename)
        expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_retry #{pid_list.first}").twice
        expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_timeout #{pid_list.first}").once
        expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_retry #{pid_list.last}").twice
        expect(log).to have_received(:puts).with("argo.bulk_metadata.bulk_log_timeout #{pid_list.last}").once

        Zip::File.open(output_zip_filename) do |open_file|
          expect(open_file.glob('*').length).to eq 0
        end
      end
    end

    context 'user lacks permission to view metadata on one of the objects' do
      before do
        allow(ability).to receive(:can?).with(:view_metadata, cocina_model1).and_return(true)
        allow(ability).to receive(:can?).with(:view_metadata, cocina_model2).and_return(false)
      end

      it 'creates a valid zip file with only the objects for which the user has view_metadata authorization' do
        expect(download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

        download_job.perform(bulk_action.id, dl_job_params)

        expect(File).to be_exist(output_zip_filename)
        Zip::File.open(output_zip_filename) do |open_file|
          expect(open_file.glob('*').map(&:name)).to eq ["#{pid_list.first}.xml"]
        end
        expect(File.read(bulk_action.log_name)).to match(/Not authorized for #{pid_list.second}/)
      end
    end
  end

  describe 'query_dor' do
    let(:log) { double('log', puts: nil, flush: nil) }

    before do
      allow(download_job).to receive(:with_bulk_action_log).and_yield(log)
    end

    it 'does not log anything upon success' do
      result = download_job.query_dor('druid:hj185xx2222', log)
      expect(result).not_to be_nil
      expect(log).not_to receive(:puts)
    end

    context 'when query fails' do
      before do
        allow(object_client1).to receive(:find).and_raise(Faraday::TimeoutError)
        allow(object_client2).to receive(:find).and_raise(Faraday::TimeoutError)
      end

      it 'returns nil' do
        result = download_job.query_dor(pid_list.first, log)
        expect(result).to be_nil
      end
    end
  end
end
