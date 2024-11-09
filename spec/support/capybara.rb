# frozen_string_literal: true

require 'capybara/rails'
require 'capybara/rspec'

Capybara.default_max_wait_time = 7
Capybara.disable_animation = true
Capybara.enable_aria_label = true

RSpec.configure do |config|
  config.include Capybara::DSL

  # Use RackTest driver by default (i.e., when JS does not need running) for performance reasons
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # Use a Selenium-based driver when a test involves running client-side code
  config.before(:each, type: :system, js: true) do # rubocop:disable RSpec/MetadataStyle, RSpec/SortMetadata
    driven_by :selenium, using: ENV['NO_HEADLESS'].present? ? :chrome : :headless_chrome, screen_size: [1920, 1400]
  end
end
