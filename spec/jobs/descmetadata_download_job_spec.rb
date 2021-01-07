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
  let(:pid_list) { [item1.pid, item2.pid] }
  let(:dl_job_params) do
    { pids: pid_list }
  end
  let(:item1) { Dor::Item.new(pid: 'druid:hj185xx2222') }
  let(:item2) { Dor::Item.new(pid: 'druid:kv840xx0000') }

  before do
    allow(Dor).to receive(:find).with(pid_list[0]).and_return(item1)
    allow(Dor).to receive(:find).with(pid_list[1]).and_return(item2)
  end

  after do
    FileUtils.rm_rf(output_directory) if Dir.exist?(output_directory)
  end

  describe '#zip_filename' do
    it 'returns a filename of the correct form' do
      expect(download_job.zip_filename).to eq(output_zip_filename)
    end
  end

  describe 'start_log' do
    let(:log) { double('log') }

    before { allow(log).to receive(:flush) }

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
      allow(ability).to receive(:can?).with(:view_metadata, kind_of(ActiveFedora::Base)).and_return(true)
    end

    after do
      FileUtils.rm('foo.txt')
    end

    it 'creates a valid zip file' do
      expect(download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

      download_job.perform(bulk_action.id, dl_job_params)
      expect(File).to be_exist(output_zip_filename)
      Zip::File.open(output_zip_filename) do |open_file|
        expect(open_file.glob('*').map(&:name).sort).to eq ["#{pid_list.first}.xml", "#{pid_list.second}.xml"].sort
      end
    end

    it 'retries DOR connections upon failure' do
      dor_double = class_double('Dor').as_stubbed_const(transfer_nested_constants: false)
      expect(dor_double).to receive(:find).exactly(pid_list.length * 3).times.and_raise(RestClient::RequestTimeout)
      allow(bulk_action).to receive_message_chain(:increment, :save)
      expect(bulk_action).to receive(:increment).with(:druid_count_fail)
      expect(download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)
      download_job.perform(bulk_action.id, dl_job_params)

      expect(File).to be_exist(output_zip_filename)
      Zip::File.open(output_zip_filename) do |open_file|
        expect(open_file.glob('*').length).to eq 0
      end
    end

    context 'user lacks permission to view metadata on one of the objects' do
      before do
        allow(ability).to receive(:can?).with(:view_metadata, kind_of(ActiveFedora::Base)).and_return(true)
        allow(ability).to receive(:can?).with(:view_metadata, satisfy { |obj| obj.id == pid_list.second }).and_return(false)
      end

      it 'creates a valid zip file with only the objects for which the user has view_metadata authorization' do
        expect(download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

        download_job.perform(bulk_action.id, dl_job_params)

        expect(File).to be_exist(output_zip_filename)
        Zip::File.open(output_zip_filename) do |open_file|
          expect(open_file.glob('*').map(&:name)).to eq ["#{pid_list.first}.xml"]
        end
        expect(File.open(bulk_action.log_name).read).to match(/Not authorized for #{pid_list.second}/)
      end
    end
  end

  describe 'query_dor' do
    let(:log) { double('log') }

    it 'does not log anything upon success' do
      result = download_job.query_dor('druid:hj185xx2222', log)
      expect(result).not_to be_nil
      expect(log).not_to receive(:puts)
    end

    it 'attempts three connections and logs failures' do
      dor_double = class_double('Dor').as_stubbed_const(transfer_nested_constants: false)
      expect(dor_double).to receive(:find).exactly(3).times.and_raise(RestClient::RequestTimeout)
      expect(log).to receive(:puts).twice.with('argo.bulk_metadata.bulk_log_retry druid:123')
      expect(log).to receive(:puts).once.with('argo.bulk_metadata.bulk_log_timeout druid:123')
      result = download_job.query_dor('druid:123', log)
      expect(result).to eq(nil)
    end
  end
end
