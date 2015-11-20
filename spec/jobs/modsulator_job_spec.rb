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
    FileUtils.rm_rf(@output_directory) if Dir.exist?(@output_directory)
  end

  let(:fixtures_dir) { File.expand_path('../../fixtures', __FILE__) }

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
    before :each do
      @log = double('log')
      allow(@log).to receive(:flush)
    end
    it 'writes the correct information to the log' do
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_job_start .*/)
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_user .*/)
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_input_file .*/)
      expect(@log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_note .*/)
      @mj.start_log(@log, 'fakeuser', 'fakefile', 'fakenote')
    end

    it 'completes without erring given a nil argument for note, or no arg' do
      allow(@log).to receive(:puts)
      expect { @mj.start_log(@log, 'fakeuser', 'fakefile', nil) }.not_to raise_error
      expect { @mj.start_log(@log, 'fakeuser', 'fakefile')      }.not_to raise_error
    end
  end

  describe 'save_metadata_xml' do
    before :each do
      @xml_path = File.join(fixtures_dir, 'crowdsourcing_bridget_1.xml')
      @smx_path = File.join(@output_directory, 'smx.xml')
    end
    it 'writes an xml file correctly' do
      log = double('log')
      expect(log).to receive(:puts).with(/^argo.bulk_metadata.bulk_log_xml_timestamp .*/)
      expect(log).to receive(:puts).with('argo.bulk_metadata.bulk_log_xml_filename smx.xml')
      expect(log).to receive(:puts).with('argo.bulk_metadata.bulk_log_record_count 20')
      @mj.save_metadata_xml(File.read(@xml_path), @smx_path, log)
      expect(File.read @smx_path).to eq(File.read @xml_path)
      File.delete(@smx_path) # cleanup
      expect(File.exist? @smx_path).to be_falsey
    end
  end

  describe 'status_ok' do
    (1..9).each do |i|
      it "correctly queries the status of DOR objects (:status_code #{i})" do
        m = double
        allow(m).to receive(:status_info).and_return({ :status_code => i })
        if i == 0 || i == 1 || i == 6 || i == 7 || i == 8 || i == 9
          expect(@mj.status_ok(m)).to be_truthy
        else
          expect(@mj.status_ok(m)).to be_falsy
        end
      end
    end
  end

  describe 'in_accessioning' do
    (1..9).each do |i|
      it "returns true for DOR objects that are currently in acccessioning, false otherwise (:status_code #{i})" do
        m = double
        allow(m).to receive(:status_info).and_return({ :status_code => i })
        if i == 2 || i == 3 || i == 4 || i == 5
          expect(@mj.in_accessioning(m)).to be_truthy
        else
          expect(@mj.in_accessioning(m)).to be_falsy
        end
      end
    end
  end

  describe 'generate_xml_filename' do
    it 'creates a new filename using the correct convention' do
      expect(@mj.generate_xml_filename('/tmp/generate_xml_filename.xml')).to eq('generate_xml_filename-' + Argo::Config.bulk_metadata_xml + '.xml')
    end
  end

  describe 'perform' do
    let(:test_spreadsheet_path) { File.join(@output_directory, 'crowdsourcing_bridget_1.xlsx.20150101') }
    let(:xlsx_path) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xlsx') }
    let(:xml_path ) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xml') }
    let(:xml_data ) { File.read(xml_path) }

    it 'delivers remotely-converted data' do
      FileUtils.copy_file(xlsx_path, test_spreadsheet_path)  # perform deletes upload file, so we copy fixture
      expect(File.exist? test_spreadsheet_path).to be_truthy # confirm copy
      expect(@mj).to receive(:generate_xml).and_return(xml_data)
      @mj.perform(nil,
                  test_spreadsheet_path,
                  @output_directory,
                  'random_user',
                  'xlsx',
                  'true',
                  'anote')

      # Filename is calculated based on a millisecond timestamp, so we need to look for the generated file
      output_filename = Dir.glob("#{@output_directory}/crowdsourcing_bridget*.xml")[0]
      expect(output_filename).not_to be_nil
      expect(File.exist? output_filename).to be_truthy
      expect(File.read output_filename).to be_equivalent_to(xml_data).ignoring_attr_values('datetime', 'sourceFile')
      expect(File.exist?(File.join(@output_directory, Argo::Config.bulk_metadata_log))).to be_truthy
      expect(File.exist? test_spreadsheet_path).to be_falsey
    end
  end

  describe 'generate_xml' do
    pending
  end

end
