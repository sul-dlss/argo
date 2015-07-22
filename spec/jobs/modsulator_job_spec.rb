require 'spec_helper'
require 'nokogiri'

describe ModsulatorJob, type: :job do
  include ActiveJob::TestHelper

  before :all do
    @output_directory = File.join(File.expand_path('../../../tmp/', __FILE__), 'job_tests')
    Dir.mkdir(@output_directory) unless Dir.exist?(@output_directory)
  end


  after :all do
    if(Dir.exist?(@output_directory))
      Dir.glob(File.join(@output_directory, '*')) { |f| File.delete(f) if(!File.directory?(f)) }
      Dir.rmdir(@output_directory)
    end
  end


  describe 'perform' do
    it "correctly performs a simple job" do
      skip "reimplement as an integration test"
    end
  end

  describe 'update_metadata', :focus => :true do
    it 'raises an error given an invalid xml argument' do
      expect { ModsulatorJob.new().update_metadata('', File.new(File.join(@output_directory, 'fake_log.txt'), 'w')) }.to raise_error(/nil:NilClass/)
    end
  end
  

end
