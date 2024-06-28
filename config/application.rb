# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

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
  end
end
