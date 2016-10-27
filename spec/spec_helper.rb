ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'equivalent-xml/rspec_matchers'
require 'webmock/rspec'
WebMock.allow_net_connect!(net_http_connect_on_start: true)

require 'simplecov'
require 'coveralls'
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start
SimpleCov.profiles.define 'argo' do
  add_filter 'spec'
  add_filter 'vendor'
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
  CodeClimate::TestReporter::Formatter
])
SimpleCov.start 'argo'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {timeout: 60})
end
Capybara.javascript_driver = :poltergeist
Capybara.default_max_wait_time = 10

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

  item = item_from_foxml(File.read(fname), klass)

  if klass == ActiveFedora::Base
    item.adapt_to_cmodel
  else
    item
  end
end

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # Run each example in an ActiveRecord transaction
  config.use_transactional_fixtures = false

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.include Capybara::DSL

  config.infer_spec_type_from_file_location!
end

def log_in_as_mock_user(subject, attributes = {})
  allow(subject).to receive(:current_user).and_return(mock_user(attributes))
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
      # TODO: (?) rescue if 1 datastream failed
    end
  end

  # stub item and datastream repo access methods
  result.datastreams.each_pair do |dsid, ds|
    # if ds.is_a?(ActiveFedora::OmDatastream) && !ds.is_a?(Dor::WorkflowDs)
    #   ds.instance_eval do
    #     def content       ; self.ng_xml.to_s                 ; end
    #     def content=(val) ; self.ng_xml = Nokogiri::XML(val) ; end
    #   end
    # end
    ds.instance_eval do
      def save ; true ; end
    end
  end
  result.instance_eval do
    def save ; true ; end
  end
  result
end

def mock_user(attributes = {})
  double(:webauth_user, {
    login: 'sunetid',
    logged_in?: true,
    privgroup: [],
    groups: [],
    can_view_something?: false,
    is_admin?: false,
    is_webauth_admin?: attributes[:is_admin?],
    is_manager?: false,
    is_viewer?: false,
    roles: [],
    permitted_apos: [],
    permitted_collections: []
  }.merge(attributes))
end
