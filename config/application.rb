require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Argo
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    require 'indexer'
    require 'pid_gatherer'
    require 'bulk_reindexer'
    require 'profiler'
    require 'constants'
    require 'fileutils'

    config.active_job.queue_adapter = :delayed_job

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    initializer :after_append_asset_paths, :group => :all, :after => :append_assets_path do
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
