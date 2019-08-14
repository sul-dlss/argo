# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe ModsulatorJob, type: :job do
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
      expect { @mj.update_metadata('', '', '', '', File.new(File.join(@output_directory, 'fake_log.txt'), 'w')) }.to raise_error(/nil:NilClass/)
    end
  end

  describe 'generate_log_filename' do
    it 'returns a filename of the correct form' do
      expected_filename = File.join(@output_directory, Settings.BULK_METADATA.LOG)
      expect(@mj.generate_log_filename(@output_directory)).to eq(expected_filename)
    end

    it 'creates a directory if it does not exist' do
      dir = File.join(@output_directory, 'dirdir')
      @mj.generate_log_filename(dir)
      expect(File).to be_directory(dir)
    end
  end

  describe 'generate_original_filename' do
    it 'chops off a timestamp on the end' do
      expect(@mj.generate_original_filename('myfile.txt.20150201')).to eq('myfile.txt')
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
      @mj.start_log(@log, 'fakeuser', 'fakefile', 'fakenote')
    end

    it 'completes without erring given a nil argument for note, or no arg' do
      allow(@log).to receive(:puts)
      expect { @mj.start_log(@log, 'fakeuser', 'fakefile', nil) }.not_to raise_error
      expect { @mj.start_log(@log, 'fakeuser', 'fakefile')      }.not_to raise_error
    end
  end

  describe 'save_metadata_xml' do
    before do
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
      expect(File).not_to be_exist @smx_path
    end
  end

  describe 'status_ok' do
    (0..9).each do |i|
      it "correctly queries the status of DOR objects (:status_code #{i})" do
        m = instance_double(Dor::Item)
        allow(@mj).to receive(:status).and_return(i)
        if i == 1 || i == 6 || i == 7 || i == 8 || i == 9
          expect(@mj.status_ok(m)).to be_truthy
        else
          expect(@mj.status_ok(m)).to be_falsy
        end
      end
    end
  end

  describe 'in_accessioning' do
    (0..9).each do |i|
      it "returns true for DOR objects that are currently in acccessioning, false otherwise (:status_code #{i})" do
        m = instance_double(Dor::Item)
        allow(@mj).to receive(:status).and_return(i)
        if i == 2 || i == 3 || i == 4 || i == 5
          expect(@mj.in_accessioning(m)).to be_truthy
        else
          expect(@mj.in_accessioning(m)).to be_falsy
        end
      end
    end
  end

  describe 'accessioned' do
    (0..9).each do |i|
      it "returns true for DOR objects that are acccessioned, false otherwise (:status_code #{i})" do
        m = instance_double(Dor::Item)
        allow(@mj).to receive(:status).and_return(i)
        if i == 6 || i == 7 || i == 8
          expect(@mj.accessioned(m)).to be_truthy
        else
          expect(@mj.accessioned(m)).to be_falsy
        end
      end
    end
  end

  describe 'generate_xml_filename' do
    it 'creates a new filename using the correct convention' do
      expect(@mj.generate_xml_filename('/tmp/generate_xml_filename.xml')).to eq('generate_xml_filename-' + Settings.BULK_METADATA.XML + '.xml')
    end
  end

  describe 'commit_new_version' do
    let(:dor_test_object) { double('dor_item', pid: 'druid:123abc') }
    let(:client) { instance_double(Dor::Services::Client::Object, version: version_client) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(client)
    end

    it 'opens a new minor version with filename and username' do
      @mj.commit_new_version(dor_test_object, 'testfile.xlsx', 'username')

      expect(version_client).to have_received(:open).with(
        vers_md_upd_info: {
          significance: 'minor',
          description: 'Descriptive metadata upload from testfile.xlsx',
          opening_user_name: 'username'
        }
      )
    end
  end

  describe 'version_object' do
    before do
      @dor_object = instance_double(Dor::Item, pid: 'druid:123abc')
      @workflow = double('workflow')
      @log = double('log')
      allow(Dor::StatusService).to receive(:new).and_return(stub_service)
    end

    let(:stub_service) { instance_double(Dor::StatusService, status_info: { status_code: status_code }) }
    let(:status_code) { 6 }

    it 'writes a log error message if a version cannot be opened' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(@dor_object.pid).and_return(@workflow)
      expect(@workflow).to receive(:can_open_version?).and_return(false)
      expect(@log).to receive(:puts).with("argo.bulk_metadata.bulk_log_unable_to_version #{@dor_object.pid}")

      @mj.version_object(@dor_object, 'any_filename', 'any_user', @log)
    end

    context 'the object is in the registered state' do
      let(:status_code) { 1 }

      it 'does not update the version' do
        expect(@mj).not_to receive(:commit_new_version)

        @mj.version_object(@dor_object, 'any_filename', 'any_user', @log)
      end
    end

    context 'the object is in the opened state' do
      let(:status_code) { 9 }

      it 'does not update the version ' do
        expect(@mj).not_to receive(:commit_new_version)

        @mj.version_object(@dor_object, 'any_filename', 'any_user', @log)
      end
    end

    it 'updates the version if the object is past the registered state' do
      expect(DorObjectWorkflowStatus).to receive(:new).with(@dor_object.pid).and_return(@workflow)
      expect(@workflow).to receive(:can_open_version?).and_return(true)
      expect(@mj).to receive(:commit_new_version)

      @mj.version_object(@dor_object, 'any_filename', 'any_user', @log)
    end
  end

  describe 'perform' do
    let(:test_spreadsheet_path) { File.join(@output_directory, 'crowdsourcing_bridget_1.xlsx.20150101') }
    let(:xlsx_path) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xlsx') }
    let(:xml_path) { File.join(fixtures_dir, 'crowdsourcing_bridget_1.xml') }
    let(:xml_data) { File.read(xml_path) }

    it 'delivers remotely-converted data' do
      FileUtils.copy_file(xlsx_path, test_spreadsheet_path) # perform deletes upload file, so we copy fixture
      expect(File).to be_exist test_spreadsheet_path # confirm copy
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
      expect(File).to be_exist output_filename
      expect(File.read output_filename).to be_equivalent_to(xml_data).ignoring_attr_values('datetime', 'sourceFile')
      expect(File).to be_exist(File.join(@output_directory, Settings.BULK_METADATA.LOG))
      expect(File).not_to be_exist test_spreadsheet_path
    end

    it 'opens the log in append mode' do
      FileUtils.copy_file(xlsx_path, test_spreadsheet_path)
      expect(File).to receive(:open).with("#{@output_directory}/#{Settings.BULK_METADATA.LOG}", 'a')
      @mj.perform(nil,
                  test_spreadsheet_path,
                  @output_directory,
                  'random_user',
                  'xlsx',
                  'true',
                  'anote')
    end
  end

  describe 'generate_xml' do
    let(:log_file) { double(puts: nil) }

    context 'cleaning up an XML file' do
      it 'sends requests to the normalizer' do
        file_path = "#{::Rails.root}/spec/fixtures/crowdsourcing_bridget_1.xml"
        stub_request(:post, Settings.NORMALIZER_URL).to_return(body: 'abc')

        response = @mj.generate_xml('xml_only', file_path, 'crowdsourcing_bridget_1', log_file)
        expect(response).to eq 'abc'
      end

      it 'handles HTTP errors' do
        file_path = "#{::Rails.root}/spec/fixtures/crowdsourcing_bridget_1.xml"

        stub_request(:post, Settings.NORMALIZER_URL).to_return(status: 500)
        expect(log_file).to receive(:puts).with(/argo.bulk_metadata.bulk_log_internal_error/)

        response = @mj.generate_xml('xml_only', file_path, 'crowdsourcing_bridget_1', log_file)
        expect(response).to be_blank
      end
    end

    context 'with a spreadsheet' do
      it 'sends a request to the modsulator' do
        file_path = "#{::Rails.root}/spec/fixtures/crowdsourcing_bridget_1.xlsx"

        stub_request(:post, Settings.MODSULATOR_URL).to_return(body: 'abc')

        response = @mj.generate_xml('spreadsheet', file_path, 'crowdsourcing_bridget_1', log_file)
        expect(response).to eq 'abc'
      end
    end
  end
end
