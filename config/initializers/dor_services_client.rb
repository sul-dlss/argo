# frozen_string_literal: true

Faraday.default_connection_options = Faraday::ConnectionOptions.new(timeout: 500, open_timeout: 10)

# Configure dor-services-client to use the dor-services URL
Dor::Services::Client.configure(url: Settings.dor_services.url,
                                token: Settings.dor_services.token)
