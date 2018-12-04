# frozen_string_literal: true

if Settings.PROFILER.RACKMINI_ENABLED == true
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
