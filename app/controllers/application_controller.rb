# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied, with: -> { render status: :forbidden, plain: 'forbidden' }

  layout :determine_layout

  def allows_modification?(item)
    state_service = StateService.new(item)
    state_service.allows_modification?
  end

  def current_user
    super.tap do |cur_user|
      break unless cur_user

      cur_user.set_groups_to_impersonate session[:groups] if session[:groups]
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

  def enforce_versioning(item = @item)
    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if allows_modification?(item)

    redirect_to solr_document_path(item.id), flash: { error: 'Object cannot be modified in its current state.' }
    false
  end
end
