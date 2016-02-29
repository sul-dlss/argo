class AuthController < ApplicationController
  before_action do
    render :status => :forbidden, :text => 'forbidden' unless current_user && current_user.is_admin?
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
end
