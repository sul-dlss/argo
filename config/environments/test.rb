RubyDorServices::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  
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
      url 'https://lyberservices-test.stanford.edu:8080'
      user 'labware'
      pass 'lyberteam'
    end

    metadata do
      exist.url 'http://viewer:l3l%40nd@lyberapps-prod.stanford.edu/exist/rest'
      catalog.url 'http://lyberservices-prod.stanford.edu/catalog/mods'
    end
  end
end
