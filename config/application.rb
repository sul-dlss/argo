# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Argo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    require 'indexer'
    require 'constants'

    # Configure action_dispatch to handle not found errors
    config.action_dispatch.rescue_responses['Blacklight::Exceptions::RecordNotFound'] = :not_found
  end

  ARGO_VERSION = File.read(File.join(Rails.root, 'VERSION'))
  class << self
    def version
      ARGO_VERSION
    end
  end
end

# Make Zeitwerks happy.
Rails.autoloaders.main.ignore(Rails.root.join('app/packs'))
