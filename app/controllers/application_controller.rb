# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied, with: -> { render status: :forbidden, plain: 'forbidden' }

  layout :determine_layout

  def open?(cocina_object)
    VersionService.open?(druid: cocina_object.externalIdentifier)
  end

  def current_user
    super.tap do |cur_user|
      break unless cur_user

      cur_user.set_groups_to_impersonate session[:groups] if session[:groups]
      # TODO: Perhaps move these to the the LoginController and cache on the user model?
      cur_user.display_name = request.env['displayName']
      cur_user.webauth_groups = if request.env['eduPersonEntitlement']
                                  request.env['eduPersonEntitlement'].split(';')
                                else
                                  # NOTE: config.user_groups is only defined in the development environment
                                  Rails.application.config.try(:user_groups) || []
                                end
    end
  end

  def default_html_head
    stylesheet_links << ['argo']
  end

  protected

  def enforce_versioning
    if @cocina.is_a? NilModel
      return redirect_to solr_document_path(@cocina.externalIdentifier),
                         flash: { error: 'Unable to retrieve the cocina model' }
    end

    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if open?(@cocina)

    redirect_to solr_document_path(@cocina.externalIdentifier),
                flash: { error: 'Object cannot be modified in its current state.' }
    false
  end
end
