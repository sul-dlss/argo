class AuthController < ApplicationController
  def remember_impersonated_groups
    groups = params[:groups].split(',')
    session[:groups] = groups
    redirect_to root_path
  end

  def forget_impersonated_groups
    session[:groups] = nil
    redirect_to root_path
  end
end
