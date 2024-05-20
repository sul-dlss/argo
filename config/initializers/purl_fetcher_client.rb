# frozen_string_literal: true

PurlFetcher::Client.configure(url: Settings.purl_fetcher.url, token: Settings.purl_fetcher.token)
