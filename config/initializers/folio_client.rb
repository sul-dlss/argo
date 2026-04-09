# frozen_string_literal: true

# Configure folio_client singleton
FolioClient.configure(
  url: Settings.catalog.folio.okapi.url,
  login_params: {
    username: Settings.catalog.folio.okapi.username,
    password: Settings.catalog.folio.okapi.password
  },
  tenant_id: Settings.catalog.folio.tenant_id,
  user_agent: "folio_client #{FolioClient::VERSION}; argo #{Rails.env}"
)
