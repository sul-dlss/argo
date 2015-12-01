Argo::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # cache configuration
  config.perform_caching = true

  require 'rack-webauth/test'
  if Settings.WEBAUTH
    config.middleware.use(
      Rack::Webauth::Test,
      user: Settings.WEBAUTH.USER,
      mail: Settings.WEBAUTH.MAIL,
      ldapprivgroup: Settings.WEBAUTH.LDAPPRIVGROUP,
      suaffiliation: Settings.WEBAUTH.SUAFFILIATION,
      displayname: Settings.WEBAUTH.DISPLAYNAME,
      ldapauthrule: Settings.WEBAUTH.LDAPAUTHRULE
    )
  end
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
