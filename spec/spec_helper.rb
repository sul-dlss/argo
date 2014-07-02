require 'simplecov'
SimpleCov.start

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/rspec'
require 'pry-debugger'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.

def instantiate_fixture druid, klass = ActiveFedora::Base
  @fixture_dir = fixture_dir = File.join(File.dirname(__FILE__),"fixtures")
  mask = File.join(@fixture_dir,"*_#{druid.sub(/:/,'_')}.xml")
  fname = Dir[mask].first
  return nil if fname.nil?
  item_from_foxml(File.read(fname), klass)
end

def read_fixture fname
  File.read(File.join(@fixture_dir,fname))
end
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.include Capybara::DSL

  config.infer_spec_type_from_file_location!
end

def log_in_as_mock_user(subject)
  subject.stub(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true))
end

def item_from_foxml(foxml, item_class = Dor::Base)
  foxml = Nokogiri::XML(foxml) unless foxml.is_a?(Nokogiri::XML::Node)
  xml_streams = foxml.xpath('//foxml:datastream')
  properties = Hash[foxml.xpath('//foxml:objectProperties/foxml:property').collect { |node| 
    [node['NAME'].split(/#/).last, node['VALUE']] 
  }]
  result = item_class.new(:pid => foxml.root['PID'])
  result.label = properties['label']
  result.owner_id = properties['ownerId']
  xml_streams.each do |stream|
    begin
    content = stream.xpath('.//foxml:xmlContent/*').first.to_xml
    dsid = stream['ID']
    ds = result.datastreams[dsid]
    if ds.nil?
      ds = ActiveFedora::NokogiriDatastream.new(result,dsid)
      result.add_datastream(ds)
    end
  
    
    if ds.is_a?(ActiveFedora::NokogiriDatastream)
      result.datastreams[dsid] = ds.class.from_xml(Nokogiri::XML(content), ds)
    elsif ds.is_a?(ActiveFedora::RelsExtDatastream)
      result.datastreams[dsid] = ds.class.from_xml(content, ds)
    else
      result.datastreams[dsid] = ds.class.from_xml(ds, stream)
    end
  rescue
    #rescue if 1 datastream failed 
  end
  end

  # stub item and datastream repo access methods
  result.datastreams.each_pair do |dsid,ds|
    if ds.is_a?(ActiveFedora::NokogiriDatastream) and not ds.is_a?(Dor::WorkflowDs)
      ds.instance_eval do
        def content       ; self.ng_xml.to_s                 ; end
        def content=(val) ; self.ng_xml = Nokogiri::XML(val) ; end
      end
    end
    ds.instance_eval do
      def save          ; return true                      ; end
    end
  end
  result.instance_eval do
    def save ; return true ; end
  end
  result
end
