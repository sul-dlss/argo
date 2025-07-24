# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:test_login]
  skip_authorization_check only: [:test_login]
  before_action(except: %i[forget_impersonated_groups test_login]) do
    authorize! :impersonate, User
  end

  def groups
    # does default render
  end

  def remember_impersonated_groups
    groups = params[:groups].split(',')
    session[:groups] = groups
    redirect_to root_path
  end

  def forget_impersonated_groups
    session[:groups] = nil
    redirect_to root_path
  end

  # This is used by specs to allow TestShibbolethHeaders middleware to set headers.
  # This endpoint is only available in the test environment.
  def test_login
    cookies['test_remote_user'] = params[:remote_user]
    cookies['test_groups'] = params[:groups] if params[:groups].present?
    head :ok
  end
end
