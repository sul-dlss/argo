ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'equivalent-xml/rspec_matchers'

require 'simplecov'
require 'coveralls'
SimpleCov.profiles.define 'argo' do
  add_filter 'spec'
  add_filter 'vendor'
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
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
  item_from_foxml(File.read(fname), klass)
end

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
  result
end
