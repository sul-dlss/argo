# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller

  before_action :authenticate_user!

  rescue_from CanCan::AccessDenied, with: -> { render status: :forbidden, plain: 'forbidden' }

  layout :determine_layout

  # Currently we know that not all objects are Cocina compliant, this ensures that we can at least
  # receive some object and so, at least administrators can be authorized to operate on it.
  # See: https://argo.stanford.edu/catalog?f[data_quality_ssim][]=Cocina+conversion+failed
  # @return [Cocina::Models::DRO,NilModel]
  def maybe_load_cocina(druid)
    object_client = Dor::Services::Client.object(druid)
    object_client.find
  rescue Dor::Services::Client::UnexpectedResponse
    NilModel.new(druid)
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

  def development_only!
    if Rails.env.development? || ENV['DOR_SERVICES_DEBUG_MODE']
      yield
    else
      render plain: 'Not Found', status: :not_found
    end
  end

  def enforce_versioning
    return redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: 'Unable to retrieve the cocina model' } if @cocina.is_a? NilModel

    state_service = StateService.new(@cocina.externalIdentifier, version: @cocina.version)

    # if this object has been submitted and doesn't have an open version, they cannot change it.
    return true if state_service.allows_modification?

    redirect_to solr_document_path(@cocina.externalIdentifier), flash: { error: 'Object cannot be modified in its current state.' }
    false
  end
end
