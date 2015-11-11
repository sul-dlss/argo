require 'spec_helper'
require 'fileutils'
require 'equivalent-xml'

# Integration tests for the spreadsheet bulk uploads logic.
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

  describe 'perform', integration: true do
    it 'correctly performs a simple job' do
      test_spreadsheet = 'crowdsourcing_bridget_1.xlsx.20150101'
      test_spreadsheet_path = File.join(@output_directory, test_spreadsheet)
      fixtures_dir = File.join(File.expand_path('../../fixtures', __FILE__))
      FileUtils.copy_file(File.join(fixtures_dir, 'crowdsourcing_bridget_1.xlsx'), test_spreadsheet_path)

      @mj.perform(nil,
                  test_spreadsheet_path,
                  @output_directory,
                  'random_user',
                  'xlsx',
                  'true',
                  'anote')

      # Filename is calculated based on a millisecond timestamp, so we need to look for the generated file
      xml_filename = Dir.glob("#{@output_directory}/*.xml")[0]

      expect(File.read(xml_filename)).to be_equivalent_to(File.read(File.join(fixtures_dir, 'crowdsourcing_bridget_1.xml'))).ignoring_attr_values('datetime', 'sourceFile')
      expect(File.exist?(File.join(@output_directory, Argo::Config.bulk_metadata_log))).to be_truthy
      expect(File.exist?(test_spreadsheet_path)).to be_falsey
    end

  end

end
