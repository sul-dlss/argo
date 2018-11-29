class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  before_action :authenticate_user!
  before_action :fedora_setup

  rescue_from ActiveFedora::ObjectNotFoundError, with: -> { render plain: 'Object Not Found', status: :not_found }
  rescue_from CanCan::AccessDenied, with: -> { render status: :forbidden, plain: 'forbidden' }

  layout 'application'

  def current_user
    super.tap do |cur_user|
      break unless cur_user
      if session[:groups]
        cur_user.set_groups_to_impersonate session[:groups]
      end
      # TODO: Perhaps move these to the the LoginController and cache on the user model?
      cur_user.display_name = request.env['displayName']
      if request.env['eduPersonEntitlement']
        cur_user.webauth_groups = request.env['eduPersonEntitlement'].split(';')
      elsif Rails.env.development? && ENV['ROLES']
        cur_user.webauth_groups = ENV['ROLES'].split(';')
      end
    end
  end

  def default_html_head
    stylesheet_links << ['argo']
  end

  protected

  def fedora_setup
    Dor::Config.fedora.post_config
  end

  def development_only!
    if Rails.env.development? || ENV['DOR_SERVICES_DEBUG_MODE']
      yield
    else
      render plain: 'Not Found', status: :not_found
    end
  end
end
