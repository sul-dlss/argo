# frozen_string_literal: true

# Used for testing background jobs in integration tests where we need to reload the page until the job is done.
module PageHelpers
  def reload_page_until_timeout(timeout: 10)
    browser = page.driver.browser
    content = nil

    (timeout - 1).times do
      return if yield

      sleep(0.1)

      # Deal with Selenium::WebDriver::Chrome::Driver or Capybara::RackTest::Browser
      browser.respond_to?(:refresh) ? browser.refresh : browser.navigate.refresh

      content = page.body
    end

    return if yield

    puts content
    raise Timeout::Error
  end
end

RSpec.configure do |config|
  config.include PageHelpers, type: :feature
end
