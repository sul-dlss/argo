require 'capybara/rails'

Capybara.javascript_driver = :headless_chrome

Capybara.register_driver :headless_chrome do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new.tap do |opts|
    opts.args << '--headless'
    opts.args << '--disable-gpu'
    # Workaround https://bugs.chromium.org/p/chromedriver/issues/detail?id=2650&q=load&sort=-id&colspec=ID%20Status%20Pri%20Owner%20Summary
    opts.args << '--disable-site-isolation-trials'
    opts.args << '--no-sandbox'
    opts.args << '--window-size=1280,1696'
  end
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end
