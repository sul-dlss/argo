# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ModsulatorJob, type: :job do
  before do
    Dir.mkdir(output_directory) unless Dir.exist?(output_directory)
  end

  after do
    FileUtils.rm_rf(output_directory) if Dir.exist?(output_directory)
  end

  let(:output_directory) { File.join(File.expand_path('../../tmp', __dir__), 'job_tests') }
  let(:job) { ModsulatorJob.new }
  let(:fixtures_dir) { File.expand_path('../fixtures', __dir__) }
  let(:user) { build(:user, sunetid: 'foo') }

  describe 'update_metadata' do
    it 'raises an error given an invalid xml argument' do
      expect { job.update_metadata('', '', '', '', File.new(File.join(output_directory, 'fake_log.txt'), 'w')) }.to raise_error(/nil:NilClass/)
    end
  end

  describe 'generate_log_filename' do
    it 'returns a filename of the correct form' do
      expected_filename = File.join(output_directory, Settings.bulk_metadata.log)
      expect(job.generate_log_filename(output_directory)).to eq(expected_filename)
    end

    it 'creates a directory if it does not exist' do
      dir = File.join(output_directory, 'dirdir')
      job.generate_log_filename(dir)
      expect(File).to be_directory(dir)
    end
  end

  describe 'generate_original_filename' do
    it 'chops off a timestamp on the end' do
      expect(job.generate_original_filename('myfile.txt.20150201')).to eq('myfile.txt')
    end
  end

  describe 'start_log' do
    let(:log) { instance_double(File, flush: true, puts: true) }

    it 'writes the correct information to the log' do
      job.start_log(log, user, 'fakefile', 'fakenote')
      expect(log).to have_received(:puts).with(/^argo.bulk_metadata.bulk_log_job_start .*/)
      expect(log).to have_received(:puts).with(/^argo.bulk_metadata.bulk_log_user .*/)
      expect(log).to have_received(:puts).with(/^argo.bulk_metadata.bulk_log_input_file .*/)
      expect(log).to have_received(:puts).with(/^argo.bulk_metadata.bulk_log_note .*/)
    end

    it 'completes without erring given a nil argument for note, or no arg' do
      expect { job.start_log(log, user, 'fakefile', nil) }.not_to raise_error
      expect { job.start_log(log, user, 'fakefile')      }.not_to raise_error
    end
  end

  describe 'save_metadata_xml' do
    let(:xml_path) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xml') }
    let(:smx_path) { File.join(output_directory, 'smx.xml') }
    let(:log) { instance_double(File, puts: true) }

    after do
      File.delete(smx_path) # cleanup
    end

    it 'writes an xml file correctly' do
      job.save_metadata_xml(File.read(xml_path), smx_path, log)
      expect(log).to have_received(:puts).with(/^argo.bulk_metadata.bulk_log_xml_timestamp .*/)
      expect(log).to have_received(:puts).with('argo.bulk_metadata.bulk_log_xml_filename smx.xml')
      expect(log).to have_received(:puts).with('argo.bulk_metadata.bulk_log_record_count 20')
      expect(File.read(smx_path)).to eq File.read(xml_path)
    end
  end

  describe 'generate_xml_filename' do
    it 'creates a new filename using the correct convention' do
      expect(job.generate_xml_filename('/tmp/generate_xml_filename.xml')).to eq('generate_xml_filename-' + Settings.bulk_metadata.xml + '.xml')
    end
  end

  describe 'perform' do
    let(:test_spreadsheet_path) { File.join(output_directory, 'crowdsourcing_bridget_1.xlsx.20150101') }
    let(:xlsx_path) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xlsx') }
    let(:xml_path) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xml') }
    let(:xml_data) { File.read(xml_path) }

    it 'delivers remotely-converted data' do
      FileUtils.copy_file(xlsx_path, test_spreadsheet_path) # perform deletes upload file, so we copy fixture
      expect(File).to be_exist test_spreadsheet_path # confirm copy
      expect(ModsulatorClient).to receive(:convert_spreadsheet_to_mods).and_return(xml_data)
      job.perform(nil,
                  test_spreadsheet_path,
                  output_directory,
                  user,
                  [],
                  'xlsx',
                  'anote')

      # Filename is calculated based on a millisecond timestamp, so we need to look for the generated file
      output_filename = Dir.glob("#{output_directory}/crowdsourcing_bridget*.xml")[0]
      expect(output_filename).not_to be_nil
      expect(File).to be_exist output_filename
      expect(File.read(output_filename)).to be_equivalent_to(xml_data).ignoring_attr_values('datetime', 'sourceFile')
      expect(File).to be_exist(File.join(output_directory, Settings.bulk_metadata.log))
      expect(File).not_to be_exist test_spreadsheet_path
    end

    it 'opens the log in append mode' do
      FileUtils.copy_file(xlsx_path, test_spreadsheet_path)
      expect(File).to receive(:open).with("#{output_directory}/#{Settings.bulk_metadata.log}", 'a')
      job.perform(nil,
                  test_spreadsheet_path,
                  output_directory,
                  user,
                  [],
                  'xlsx',
                  'anote')
    end
  end
end
