require 'active_support/cache/dalli_store'
require 'action_dispatch/middleware/session/dalli_store'

Argo::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  config.cache_store = :dalli_store, { namespace: Settings.CACHE_STORE_NAME }

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  #Set how deprecation warnings are handled.
  config.active_support.deprecation = :log

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

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
  config.assets.precompile << 'about.css.sass' << 'argo.css' << 'registration.css' << 'report.css' << 'webcrop.css' << '*.js' << '*.coffee'

  Argo.configure do
    reindex_on_the_fly      Settings.REINDEX_ON_FLY
    date_format_str         Settings.DATE_FORMAT_STR
    urls do
      stacks_file           Settings.STACKS_FILE_URL
      stacks                Settings.STACKS_URL
      mdtoolkit             Settings.MDTOOLKIT_URL
      purl                  Settings.PURL_URL
      dor_services          Settings.DOR_SERVICES_URL
      workflow              Settings.WORKFLOW_URL
      robot_status          Settings.ROBOT_STATUS_URL
      modsulator            Settings.MODSULATOR_URL
      normalizer            Settings.NORMALIZER_URL
      spreadsheet           Settings.SPREADSHEET_URL
    end
    bulk_metadata_directory Settings.BULK_METADATA.DIRECTORY # Directory for storing bulk metadata job info
    bulk_metadata_log       Settings.BULK_METADATA.LOG       # Bulk metadata log file
    bulk_metadata_csv_log   Settings.BULK_METADATA.CSV_LOG   # Bulk metadata log file in CSV format for end users
    bulk_metadata_xml       Settings.BULK_METADATA.XML       # Bulk metadata XML output file
  end

  # the following config statement gets us two important things on each log line:
  # 1) unique IDs per request, so that it's easier to correlate
  # logging statements associated with a given request when multiple
  # simultaneous requests have interleaved log statements.
  # 2) time stamps on each log statement, because knowing when something
  # got logged is quite nice.
  # (declared after Argo.configure since it uses one of those params)
  config.log_tags = [:uuid, proc {DateTime.now.strftime(Argo::Config.date_format_str)}]
end
