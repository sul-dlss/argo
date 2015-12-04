if ENV['COVERAGE'] && RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  SimpleCov.start
end

ENV['RAILS_ENV'] ||= 'test'

##
# Requires the WebMock testing framework which is bundled in the :test environment.
# We require that all outbound HTTP requests be stubbed out, except those to 
# our jetty instance on localhost. This needs to be initialized before the rails 
# app is initialized.
#
require 'webmock'
include WebMock::API
WebMock.disable_net_connect!(allow_localhost: true) # assumes FEDORA_URL and SOLRIZER_URL are localhost

# Initialize the application
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'equivalent-xml/rspec_matchers'
require 'coveralls'
Coveralls.wear!('rails')

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {timeout: 60})
end
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 10

# We stub out some of the Workflow Service requests
def mock_workflow_requests
  # stub_request(:any, Settings.WORKFLOW_URL).to_return(status: 404)
  escaped_url = Settings.WORKFLOW_URL.gsub('/', '\/')
  stub_request(:get, /#{escaped_url}workflow_archive.*/).
    to_return(body: '<objects count="1"/>')
  stub_request(:get, /#{escaped_url}dor.*/).
    to_return(body: '<workflows/>')
end
mock_workflow_requests

def mock_status_requests
  stub_request(:get, Settings.STATUS_INDEXER_URL).to_return(status: 404)
end
mock_status_requests

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
#
# Note: no such files, currently.
Dir[Rails.root.join('spec/support/**/*.rb')].each {|f| require f}

def druid_to_path(druid, flavor = 'xml')
  fixture_mask = File.join(File.dirname(__FILE__), 'fixtures', "*_#{druid.sub(/:/, '_')}.#{flavor}")
  other_mask   = Rails.root.join('fedora_conf', 'data', "#{druid.sub(/druid:/, '')}.#{flavor}")
  Dir[fixture_mask].first || Dir[other_mask].first
end

def instantiate_fixture(druid, klass = ActiveFedora::Base)
  fname = druid_to_path(druid)
  Rails.logger.debug "instantiate_fixture(#{druid}) ==> #{fname}"
  return nil if fname.nil?
  item_from_foxml(File.read(fname), klass)
end

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Run each example in an ActiveRecord transaction
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.include Capybara::DSL

  config.infer_spec_type_from_file_location!
end

def log_in_as_mock_user(subject)
  allow(subject).to receive(:webauth).and_return(double(:webauth_user, :login => 'sunetid', :logged_in? => true))
end

# Highly similar to https://github.com/sul-dlss/dor-services/blob/master/spec/foxml_helper.rb
def item_from_foxml(foxml, item_class = Dor::Base, other_class = ActiveFedora::OmDatastream)
  foxml = Nokogiri::XML(foxml) unless foxml.is_a?(Nokogiri::XML::Node)
  xml_streams = foxml.xpath('//foxml:datastream')
  properties = Hash[foxml.xpath('//foxml:objectProperties/foxml:property').collect { |node|
    [node['NAME'].split(/#/).last, node['VALUE']]
  }]
  result = item_class.new(:pid => foxml.root['PID'])
  result.label    = properties['label']
  result.owner_id = properties['ownerId']
  xml_streams.each do |stream|
    begin
      content = stream.xpath('.//foxml:xmlContent/*').first.to_xml
      dsid = stream['ID']
      ds = result.datastreams[dsid]
      if ds.nil?
        ds = other_class.new(result, dsid)
        result.add_datastream(ds)
      end

      if ds.is_a?(other_class)
        result.datastreams[dsid] = ds.class.from_xml(Nokogiri::XML(content), ds)
      elsif ds.is_a?(ActiveFedora::RelsExtDatastream)
        result.datastreams[dsid] = ds.class.from_xml(content, ds)
      else
        result.datastreams[dsid] = ds.class.from_xml(ds, stream)
      end
    rescue
      # rescue if 1 datastream failed
    end
  end

  # stub item and datastream repo access methods
  # rubocop:disable Style/SingleLineMethods
  result.datastreams.each_pair do |dsid, ds|
    if ds.is_a?(other_class) && !ds.is_a?(Dor::WorkflowDs)
      ds.instance_eval do
        def content       ; ng_xml.to_s                 ; end
        def content=(val) ; self.ng_xml = Nokogiri::XML(val) ; end
      end
    end
    ds.instance_eval do
      def save          ; true                      ; end
    end
  end
  result.instance_eval do
    def save ; true ; end
  end
  result
end
