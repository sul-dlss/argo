# frozen_string_literal: true

require 'jwt'

module JwtHelper
  def generate_test_token
    JWT.encode({ sub: 'testing' }, Settings.dor.hmac_secret, 'HS256')
  end
end
