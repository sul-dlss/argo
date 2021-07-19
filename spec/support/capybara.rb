# typed: strict
# frozen_string_literal: true

require 'capybara/apparition'
require 'capybara/rails'
require 'capybara/rspec'

# Uncomment for a headed browser:
# Capybara.register_driver :apparition do |app|
#   Capybara::Apparition::Driver.new(app, headless: false)
# end

Capybara.javascript_driver = :apparition
Capybara.disable_animation = true
Capybara.enable_aria_label = true
Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 7 # default is 2
