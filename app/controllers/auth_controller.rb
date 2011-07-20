class AuthController < ApplicationController

  def login
    redirect_to params[:return]
  end
  
end
