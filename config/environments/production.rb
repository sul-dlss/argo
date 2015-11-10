require 'active_support/cache/dalli_store'
require 'action_dispatch/middleware/session/dalli_store'

Argo::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Dalli cache configuration
  config.perform_caching = true
  config.cache_store = :dalli_store, { namespace: Settings.CACHE_STORE_NAME }
  config.cache_store.logger.level = Logger::DEBUG

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.middleware.use(Rack::Webauth)

  Argo.configure do
    reindex_on_the_fly      Settings.REINDEX_ON_FLY
    date_format_str         Settings.DATE_FORMAT_STR
    urls do
      mdtoolkit             Settings.MDTOOLKIT_URL
      purl                  Settings.PURL_URL
      stacks                Settings.STACKS_URL
      stacks_file           Settings.STACKS_FILE_URL
      dor_services          Settings.DOR_SERVICES_URL
      workflow              Settings.WORKFLOW_URL
      dpg                   Settings.DPG_URL
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
  config.log_tags = [:uuid, proc {Time.zone.now.strftime(Argo::Config.date_format_str)}]
end
