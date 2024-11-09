# frozen_string_literal: true

# Used for testing background jobs in integration tests where we need to reload the page until the job is done.
module PageHelpers
  TRIES = 10

  def reload_page_until_timeout
    browser = page.driver.browser
    content = nil

    TRIES.times do
      return if yield

      sleep(1)

      # Deal with Selenium::WebDriver::Chrome::Driver or Capybara::RackTest::Browser
      browser.respond_to?(:refresh) ? browser.refresh : browser.navigate.refresh

      content = page.body
    end

    return if yield

    raise Timeout::Error
  end
end

RSpec.configure do |config|
  config.include PageHelpers, type: :system
end
