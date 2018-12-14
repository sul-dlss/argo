# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# this is intended to silence deprecation warnings when running rake tasks via
# cron, to prevent cron jobs from flooding us with emails about deprecation warnings.
# you probably should not use this flag for anything else.
ActiveSupport::Deprecation.behavior = [:silence] if ENV['SILENCE_DEPRECATION_WARNINGS']

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Argo
  class Application < Rails::Application
    # Initialize configuration defaults
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    require 'indexer'
    require 'constants'
    require 'fileutils'

    config.active_job.queue_adapter = :delayed_job

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    initializer :after_append_asset_paths, group: :all, after: :append_assets_path do
      config.assets.paths.unshift Rails.root.join('app', 'assets', 'stylesheets', 'jquery-ui', 'custom-theme').to_s
    end
  end

  ARGO_VERSION = File.read(File.join(Rails.root, 'VERSION'))

  class << self
    def version
      ARGO_VERSION
    end
  end
end
