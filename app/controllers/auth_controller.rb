class AuthController < ApplicationController

  def login
    session[:webauth_env] = Hash[webauth.env.select { |k,v| k.to_s =~ /^WEBAUTH_/ }].to_json
    redirect_to params[:return]
  end
  
end
