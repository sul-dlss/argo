# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe DescmetadataDownloadJob, type: :job do
  before :all do
    @output_directory = File.join(File.expand_path('../../../tmp/', __FILE__), 'descmetadata_download_job_spec')
    @output_zip_filename = File.join(@output_directory, Settings.BULK_METADATA.ZIP)
    @download_job = described_class.new
    @pid_list_short = ['druid:hj185vb7593']
    @pid_list_long = ['druid:hj185vb7593', 'druid:kv840rx2720']
    @zip_params_short = {
      output_directory: @output_directory,
      pids: @pid_list_short
    }
    @zip_params_long = {
      output_directory: @output_directory,
      pids: @pid_list_long
    }
  end

  after do
    FileUtils.rm_rf(@output_directory) if Dir.exist?(@output_directory)
  end

  describe 'generate_zip_filename' do
    it 'returns a filename of the correct form' do
      expect(@download_job.generate_zip_filename(@output_directory)).to eq(@output_zip_filename)
    end
  end

  describe 'start_log' do
    before do
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
      expect(zip).to receive(:get_output_stream).with("#{druid}.xml").and_yield(output_file)
      expect(output_file).to receive(:puts).with(string_value)
      @download_job.write_to_zip(string_value, druid, zip)
    end
  end

  describe 'perform' do
    let(:ability) { instance_double(Ability) }

    before do
      allow(Ability).to receive(:new).and_return(ability)
      allow(ability).to receive(:can?).with(:view_metadata, kind_of(ActiveFedora::Base)).and_return(true)
    end

    after do
      FileUtils.rm('foo.txt')
    end

    it 'creates a valid zip file' do
      bulk_action = create(:bulk_action,
                           action_type: 'DescmetadataDownloadJob',
                           pids: @pid_list_long,
                           log_name: 'foo.txt')
      expect(@download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

      @download_job.perform(bulk_action.id, @zip_params_long)

      expect(File).to be_exist(@output_zip_filename)
      Zip::File.open(@output_zip_filename) do |open_file|
        expect(open_file.glob('*').length).to eq 2
      end
    end

    it 'retries DOR connections upon failure' do
      dor_double = class_double('Dor').as_stubbed_const(transfer_nested_constants: false)
      expect(dor_double).to receive(:find).exactly(3).times.and_raise(RestClient::RequestTimeout)
      bulk_action = create(:bulk_action,
                           action_type: 'DescmetadataDownloadJob',
                           pids: @pid_list_short,
                           log_name: 'foo.txt')
      allow(bulk_action).to receive_message_chain(:increment, :save)
      expect(bulk_action).to receive(:increment).with(:druid_count_fail)
      expect(@download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

      @download_job.perform(bulk_action.id, @zip_params_short)

      expect(File).to be_exist(@output_zip_filename)
      Zip::File.open(@output_zip_filename) do |open_file|
        expect(open_file.glob('*').length).to eq 0
      end
    end

    context 'user lacks permission to view metadata on one of the objects' do
      before do
        allow(ability).to receive(:can?).with(:view_metadata, kind_of(ActiveFedora::Base)).and_return(true)
        allow(ability).to receive(:can?).with(:view_metadata, satisfy { |obj| obj.id == @pid_list_long.second }).and_return(false)
      end

      it 'creates a valid zip file with only the objects for which the user has view_metadata authorization' do
        bulk_action = create(:bulk_action,
                             action_type: 'DescmetadataDownloadJob',
                             pids: @pid_list_long,
                             log_name: 'foo.txt')
        expect(@download_job).to receive(:bulk_action).and_return(bulk_action).at_least(:once)

        @download_job.perform(bulk_action.id, @zip_params_long)

        expect(File).to be_exist(@output_zip_filename)
        Zip::File.open(@output_zip_filename) do |open_file|
          expect(open_file.glob('*').map(&:name)).to eq ["#{@pid_list_long.first}.xml"]
        end
      end
    end
  end

  describe 'query_dor' do
    before do
      @log = double('log')
    end

    it 'does not log anything upon success' do
      result = @download_job.query_dor('druid:hj185vb7593', @log)
      expect(result).not_to be_nil
      expect(@log).not_to receive(:puts)
    end

    it 'attempts three connections and logs failures' do
      dor_double = class_double('Dor').as_stubbed_const(transfer_nested_constants: false)
      expect(dor_double).to receive(:find).exactly(3).times.and_raise(RestClient::RequestTimeout)
      expect(@log).to receive(:puts).twice.with('argo.bulk_metadata.bulk_log_retry druid:123')
      expect(@log).to receive(:puts).once.with('argo.bulk_metadata.bulk_log_timeout druid:123')
      result = @download_job.query_dor('druid:123', @log)
      expect(result).to eq(nil)
    end
  end
end
