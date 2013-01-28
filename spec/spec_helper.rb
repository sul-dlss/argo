# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/rspec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
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
end

def stub_config
  @fixture_dir = fixture_dir = File.join(File.dirname(__FILE__),"fixtures")
  Dor::Config.push! do
    suri.mint_ids false
    gsearch do
      url "http://solr.edu/gsearch"
      rest_url "http://fedora.edu/gsearch/rest"
    end
    solrizer.url "http://solr.edu/solrizer"
    fedora.url "http://fedora.edu/fedora"
    stacks.local_workspace_root File.join(fixture_dir, "workspace")
    sdr.local_workspace_root File.join(fixture_dir, "workspace")
    sdr.local_export_home File.join(fixture_dir, "export")
  end

  Rails.stub_chain(:logger, :error)
  ActiveFedora.stub!(:fedora).and_return(stub('frepo').as_null_object)
end

def unstub_config
  Dor::Config.pop!
end

def instantiate_fixture druid, klass = ActiveFedora::Base
  mask = File.join(@fixture_dir,"*_#{druid.sub(/:/,'_')}.xml")
  fname = Dir[mask].first
  return nil if fname.nil?
  item_from_foxml(File.read(fname), klass)
end

def log_in_as_mock_user(subject)
  subject.stub(:webauth).and_return(mock(:webauth_user, :login => 'sunetid', :logged_in? => true))
end
