# frozen_string_literal: true

require 'simplecov'
SimpleCov.start :rails do
  add_filter '/spec/'
  add_filter '/vendor/'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

RSpec.configure do |config|
  config.order = :random
  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.example_status_persistence_file_path = 'examples.txt'
end
