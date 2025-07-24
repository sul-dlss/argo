# frozen_string_literal: true

# This is a Rack middleware that we use in testing. It injects headers
# that simulate mod_shib so we can test.
class TestShibbolethHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    env['REMOTE_USER'] = request.cookies['test_remote_user']
    env['eduPersonEntitlement'] = request.cookies['test_groups']
    @app.call(env)
  end
end
