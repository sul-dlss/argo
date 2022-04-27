# frozen_string_literal: true

if Rails.env.development? && ENV.fetch('REMOTE_DEBUGGER', nil) == 'byebug'
  require 'byebug/core'

  debugger_host = ENV.fetch('DEBUGGER_HOST', 'localhost')
  debugger_port = ENV.fetch('DEBUGGER_PORT', 8989).to_i

  begin
    Byebug.start_server(debugger_host, debugger_port)
  rescue Errno::EADDRINUSE
    Rails.logger.error("Debugger already running on #{debugger_host}:#{debugger_port}! Change `DEBUGGER_HOST` and/or `DEBUGGER_PORT` and try again.")
  end
end
