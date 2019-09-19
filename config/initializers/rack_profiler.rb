# frozen_string_literal: true

if Settings.profiler.rackmini_enabled == true
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
