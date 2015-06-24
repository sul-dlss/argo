if ENV['COVERAGE'] && RUBY_VERSION =~ /^1.9/
  require 'simplecov'
  SimpleCov.start
end

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'equivalent-xml/rspec_matchers'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
#
# Note: no such files, currently.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

def druid_to_path druid, flavor = 'xml'
  fixture_mask = File.join(File.dirname(__FILE__),"fixtures","*_#{druid.sub(/:/,'_')}.#{flavor}")
  other_mask   = Rails.root.join("fedora_conf","data","#{druid.sub(/druid:/,'')}.#{flavor}")
  return Dir[fixture_mask].first || Dir[other_mask].first
end

def instantiate_fixture druid, klass = ActiveFedora::Base
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
        ds = other_class.new(result,dsid)
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
      #rescue if 1 datastream failed
    end
  end

  # stub item and datastream repo access methods
  # rubocop:disable Style/SingleLineMethods
  result.datastreams.each_pair do |dsid,ds|
    if ds.is_a?(other_class) && !ds.is_a?(Dor::WorkflowDs)
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
