# frozen_string_literal: true

###
#  Simple controller to handle login and redirect
###
class LoginController < ApplicationController
  def login
    if params[:referrer].present?
      redirect_to params[:referrer]
    else
      redirect_back_or_to(root_url)
    end
  end
end
