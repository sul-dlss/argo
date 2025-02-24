require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Argo
  mattr_accessor :verifier

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    require 'constants'

    # Configure action_dispatch to handle not found errors
    config.action_dispatch.rescue_responses['Blacklight::Exceptions::RecordNotFound'] = :not_found
    config.action_dispatch.rescue_responses['Dor::Services::Client::NotFoundResponse'] = :not_found

    config.after_initialize do |app|
      Argo.verifier = app.message_verifier('Argo')
      Cocina::Models::Mapping::Purl.base_url = Settings.purl_url
    end

    # Add timestamps to all loggers (both Rack-based ones and e.g. Sidekiq's)
    config.log_formatter = proc do |severity, datetime, _progname, msg|
      "[#{datetime.to_fs(:iso8601)}] [#{severity}] #{msg}\n"
    end

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
