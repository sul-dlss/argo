# frozen_string_literal: true

require 'capybara/rails'

Capybara.register_driver :headless_chrome do |app|
  options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.add_argument('--headless')
    opts.add_argument('--disable-gpu')
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.add_argument('--disable-site-isolation-trials')
    opts.add_argument('--window-size=1920,1080')
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end

Capybara.default_max_wait_time = 7
Capybara.disable_animation = true
Capybara.javascript_driver = :headless_chrome

Capybara::Screenshot.register_driver(:headless_chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end
