class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user. Blacklight depends on
  # this method in order to perform user specific actions.

  before_action :authenticate_user!
  before_action :fedora_setup

  rescue_from ActiveFedora::ObjectNotFoundError, with: -> { render plain: 'Object Not Found', status: :not_found }
  rescue_from CanCan::AccessDenied, with: -> { render status: :forbidden, plain: 'forbidden' }

  layout 'application'

  # def current_user
  #   cur_user = nil
  #   if webauth && webauth.logged_in?
  #     cur_user = User.find_or_create_by_webauth(webauth)
  #   elsif request.env['REMOTE_USER']
  #     cur_user = User.find_or_create_by_remoteuser(request.env['REMOTE_USER'])
  #   end
  #
  #   if cur_user && session[:groups]
  #     cur_user.set_groups_to_impersonate session[:groups]
  #   end
  #
  #   cur_user
  # end

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
