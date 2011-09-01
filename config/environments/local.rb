Rails.env = 'development'

Sass::Plugin.options[:always_update] = true
RubyDorServices::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  require 'rack-webauth/test'
  config.middleware.use(Rack::Webauth::Test, :user => 'labware', :mail => 'labware@stanford.edu',
    :ldapprivgroup => 'dlss:labstaff', :suaffiliation => 'stanford:test', :displayname => 'Labware User',
    :ldapauthrule => 'valid-user')
  config.middleware.use(Rack::Webauth)
  cert_dir = File.expand_path(File.join(File.dirname(__FILE__),"../certs"))

  Dor::Config.configure do
    fedora do
      url 'https://fedoraAdmin:fedoraAdmin@dor-test.stanford.edu/fedora'
      cert_file File.join(cert_dir,"dlss-dev-test.crt")
      key_file File.join(cert_dir,"dlss-dev-test.key")
      key_pass ''
    end

    workflow.url 'https://lyberservices-test.stanford.edu/workflow/'
    gsearch.url 'https://dor-test.stanford.edu/solr'

    suri do
      mint_ids true
      id_namespace 'druid'
      url 'https://lyberservices-test.stanford.edu'
      user 'labware'
      pass 'lyberteam'
    end

    metadata do
      exist.url 'http://viewer:l3l%40nd@lyberapps-prod.stanford.edu/exist/rest'
      catalog.url 'http://lyberservices-prod.stanford.edu/catalog/mods'
    end
  end
end
