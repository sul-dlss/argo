class AuthController < ApplicationController

  def login
    session[:webauth_env] = Hash[webauth.env.select { |k,v| k.to_s =~ /^WEBAUTH_/ }].to_json
    session[:privgroup_hash] = htaccess_hash
    redirect_to params[:return] || root_path
  end
  
  def logout
    session.delete(:webauth_env)
    session.delete(:privgroup_hash)
    redirect_to root_path
  end
  
  def remember_impersonated_groups
    groups=params[:groups].split(',')
    session[:groups]=groups
    redirect_to root_path
  end
  
  def forget_impersonated_groups
    session[:groups]=nil
    redirect_to root_path
  end
  
end
