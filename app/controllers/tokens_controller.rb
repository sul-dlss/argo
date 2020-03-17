# frozen_string_literal: true

class TokensController < ApplicationController
  # GET /settings/tokens
  def index; end

  # POST /settings/tokens
  def create
    # TODO: pass an in-memory credential store.
    SdrClient::Login.run(url: Settings.sdr_api.url, login_service: LoginFromSettings)

    connection = SdrClient::Connection.new(url: Settings.sdr_api.url, token: SdrClient::Credentials.read)

    # TODO: connection.proxy("#{current_user.sunetid}@stanford.edu")
    response = connection.post("/v1/auth/proxy?to=#{current_user.sunetid}@stanford.edu")
    case response.status
    when 200
      render json: response.body
    else
      render plain: "unable to get token\n#{response.body}", status: :bad_request
    end
  end

  # This allows a login using credentials from the config gem.
  class LoginFromSettings
    def self.run
      { email: Settings.sdr_api.email, password: Settings.sdr_api.password }
    end
  end
end
