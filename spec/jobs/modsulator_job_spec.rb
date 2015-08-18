require 'spec_helper'
require 'fileutils'

describe ModsulatorJob, type: :job do
  include ActiveJob::TestHelper

  before :all do
    @output_directory = File.join(File.expand_path('../../../tmp/', __FILE__), 'job_tests')
    @mj = ModsulatorJob.new()
    Dir.mkdir(@output_directory) unless Dir.exist?(@output_directory)
  end


  after :all do
    FileUtils.rm_rf(@output_directory) if(Dir.exist?(@output_directory))
  end


  describe 'update_metadata' do
    it 'raises an error given an invalid xml argument' do
      expect { @mj.update_metadata('', '', File.new(File.join(@output_directory, 'fake_log.txt'), 'w')) }.to raise_error(/nil:NilClass/)
    end
  end
  

  describe 'generate_log_filename' do
    it 'returns a filename of the correct form' do
      expected_filename = File.join(@output_directory, Argo::Config.bulk_metadata_log)
      expect(@mj.generate_log_filename(@output_directory)).to eq(expected_filename)
    end

    it 'creates a directory if it does not exist' do
      dir = File.join(@output_directory, 'dirdir')
      @mj.generate_log_filename(dir)
      expect(File.directory?(dir)).to be_truthy
    end
  end


  describe 'generate_original_filename' do
    it 'chops off a timestamp on the end' do
      expect(@mj.generate_original_filename('myfile.txt.20150201')).to eq('myfile.txt')
    end
  end


  describe 'start_log' do
    it 'writes the correct information to the log' do
      log = double('log')
      expect(log).to receive(:puts).with(/^job_start .*/)
      expect(log).to receive(:puts).with(/^current_user .*/)
      expect(log).to receive(:puts).with(/^input_file .*/)
      expect(log).to receive(:puts).with(/^note .*/)
      @mj.start_log(log, 'fakeuser', 'fakefile', 'fakenote')
    end

    it 'completes without erring given a nil argument for note' do
      log = double('log')
      allow(log).to receive(:puts)
      expect { @mj.start_log(log, 'fakeuser', 'fakefile', nil) }.not_to raise_error
    end
  end


  describe 'save_metadata_xml' do
    it 'writes an xml file correctly' do
      fixtures_dir = File.expand_path('../../fixtures', __FILE__)
      test_xml = 'crowdsourcing_bridget_1.xml'
      log = double('log')
      expect(log).to receive(:puts).with(/^xml_written .*/)
      expect(log).to receive(:puts).with('xml_filename smx.xml')
      expect(log).to receive(:puts).with('records 20')
      @mj.save_metadata_xml(File.read(File.join(fixtures_dir, test_xml)),
                            File.join(@output_directory, 'smx.xml'),
                            log)
      expect(File.read(File.join(@output_directory, 'smx.xml'))).to eq(File.read(File.join(fixtures_dir, test_xml)))
    end
  end
end
