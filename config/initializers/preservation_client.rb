# frozen_string_literal: true

# Configure preservation-client to use preservation catalog URL
Preservation::Client.configure(url: Settings.preservation_catalog.url)
