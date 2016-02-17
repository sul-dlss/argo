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


################################################################
# Dor objects

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

################################################################
# Users

def log_in_as_mock_user(subject)
  user = double(
    :webauth_user,
    :login => 'sunetid',
    :logged_in? => true,
  )
  allow(subject).to receive(:webauth).and_return(user)
end

# A User with `is_admin` privilege.  This is the ultimate privilege.
# This user is configured to be the ApplicationController#current_user.
# @return admin_user [User] An admin user
def admin_user
  webauth = double(
    'WebAuth',
    :login => 'sunetid',
    :attributes => {'DISPLAYNAME' => 'Admin'}
  )
  admin_user = User.find_or_create_by_webauth(webauth)
  allow(admin_user).to receive(:groups).and_return(User::ADMIN_GROUPS)
  # admin privilege supercedes all others, no need to mock anything else.
  allow(admin_user).to receive(:is_admin).and_return(true)
  # Could impose additional restraints, but it's likely overkill
  # in the spec helper methods (individual specs could do so), e.g.
  # expect(admin_user).not_to receive(:is_manager)
  # expect(admin_user).not_to receive(:is_viewer)
  allow_any_instance_of(ApplicationController)
    .to receive(:current_user)
    .and_return(admin_user)
  admin_user
end

# A User without `is_admin` privilege, but with `is_manager` privilege.  The
# `is_manager` privilege will trump all lower privileges.
# This user is configured to be the ApplicationController#current_user.
# @return manager_user [User] A manager user
def manager_user
  webauth = double(
    'WebAuth',
    :login => 'sunetid',
    :attributes => {'DISPLAYNAME' => 'Manager'}
  )
  manager_user = User.find_or_create_by_webauth(webauth)
  allow(manager_user).to receive(:groups).and_return(User::MANAGER_GROUPS)
  allow(manager_user).to receive(:is_admin).and_return(false)
  allow(manager_user).to receive(:is_manager).and_return(true)
  # Could impose additional restraints, but it's likely overkill
  # in the spec helper methods (individual specs could do so), e.g.
  # expect(manager_user).not_to receive(:is_viewer)
  allow_any_instance_of(ApplicationController)
    .to receive(:current_user)
    .and_return(manager_user)
  manager_user
end

# A User without `is_admin` or `is_manager` privileges, but with `is_viewer`.
# The `is_viewer` privilege will trump all lower privileges (workgroups).
# This user is configured to be the ApplicationController#current_user.
# @return view_user [User] A viewer user
def view_user
  webauth = double(
    'WebAuth',
    :login => 'sunetid',
    :attributes => {'DISPLAYNAME' => 'Viewer'}
  )
  view_user = User.find_or_create_by_webauth(webauth)
  allow(view_user).to receive(:groups).and_return(User::VIEWER_GROUPS)
  allow(view_user).to receive(:is_admin).and_return(false)
  allow(view_user).to receive(:is_manager).and_return(false)
  allow(view_user).to receive(:is_viewer).and_return(true)
  allow_any_instance_of(ApplicationController)
    .to receive(:current_user)
    .and_return(view_user)
  view_user
end
