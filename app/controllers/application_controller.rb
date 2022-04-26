# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied, with: -> { render status: :forbidden, plain: 'forbidden' }

  layout :determine_layout

  def allows_modification?(cocina_object)
    state_service = StateService.new(cocina_object)
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
      elsif Rails.env.development?
        cur_user.webauth_groups = ENV.fetch('ROLES', '').split(';')
      end
    end
  end

  def default_html_head
    stylesheet_links << ['argo']
  end

  protected

  def enforce_versioning
    return redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if allows_modification?(@cocina)

    redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: 'Object cannot be modified in its current state.' }
    false
  end
end
