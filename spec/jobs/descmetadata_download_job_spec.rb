require 'spec_helper'
require 'fileutils'

describe DescmetadataDownloadJob, type: :job do
  include ActiveJob::TestHelper

  before :all do
    @output_directory = Settings.BULK_METADATA.DIRECTORY
    @output_zip_filename = File.join(@output_directory, Settings.BULK_METADATA.ZIP)
    @download_job = described_class.new
  end

  after :all do
    FileUtils.rm_rf(@output_directory) if Dir.exist?(@output_directory)
  end

  describe 'generate_zip_filename' do
    it 'returns a filename of the correct form' do
      expect(@download_job.generate_zip_filename(@output_directory)).to eq(@output_zip_filename)
    end
  end

  describe 'start_log' do
    before :each do
      @log = double('log')
      allow(@log).to receive(:flush)
    end
    it 'writes the correct information to the log' do
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_job_start .*/)
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_user .*/)
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_input_file .*/)
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_note .*/)
      @download_job.start_log(@log, 'fakeuser', 'fakefile', 'fakenote')
    end

    it 'completes without erring given a nil argument for note, or no arg' do
      allow(@log).to receive(:puts)
      expect { @download_job.start_log(@log, 'fakeuser', 'fakefile', nil) }.not_to raise_error
      expect { @download_job.start_log(@log, 'fakeuser', 'fakefile')      }.not_to raise_error
    end
  end

  describe 'write_to_zip' do
    it 'writes the given value to the zip file' do
      zip = double('zip_file')
      druid = 'druid:123'
      output_file = double('zip_output_file')
      string_value = 'descMetadata.xml'
      expect(zip).to receive(:get_output_stream).with(druid).and_yield(output_file)
      expect(output_file).to receive(:puts).with(string_value)
      @download_job.write_to_zip(string_value, druid, zip)
    end
  end

  describe 'perform' do
    it 'creates a valid zip file' do
      pid_list = ['druid:hj185vb7593', 'druid:kv840rx2720']
      zip_params = {
        output_directory: @output_directory,
        pids: pid_list
      }
      bulk_action = create(:bulk_action, action_type: 'DescmetadataDownloadJob', pids: pid_list)
      expect(@download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

      @download_job.perform(bulk_action.id, zip_params)

      expect(File.exist?(@output_zip_filename)).to be_truthy
      Zip::File.open(@output_zip_filename) do |open_file|
        expect(open_file.glob('*').length).to eq 2
      end
    end
  end

  describe 'initialize_counters' do
    it 'sets the three bulk job counters to zero' do
      bulk_action = double('bulk_action')
      expect(bulk_action).to receive(:update).with(druid_count_fail: 0)
      expect(bulk_action).to receive(:update).with(druid_count_success: 0)
      expect(bulk_action).to receive(:update).with(druid_count_total: 0)
      @download_job.initialize_counters(bulk_action)
    end
  end
end
