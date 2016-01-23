class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  # Please be sure to impelement current_user and user_session. Blacklight depends on
  # these methods in order to perform user specific actions.

  before_filter :authorize!
  before_filter :fedora_setup

  rescue_from ActiveFedora::ObjectNotFoundError, with: -> { render text: 'Object Not Found', status: :not_found }

  helper_method :current_or_guest_user

  include Rack::Webauth::Helpers

  attr_reader :help

  include Squash::Ruby::ControllerMethods
  enable_squash_client

  layout 'application'

  # A common method for controllers to find a Dor object.  It accepts any valid
  # PID (druid:aa111aa1111) or DRUID (aa111aa1111).  DruidTools::Druid parses
  # input and returns a uniform PID, which is input to Dor.find to obtain a Dor
  # object.
  # @see https://github.com/sul-dlss/druid-tools
  # @param druid [String]
  # @return object [ActiveFedora::Base] any Dor object
  # @raises ArgumentError
  def find_druid(druid)
    druid = DruidTools::Druid.new(druid).druid
    Dor.find(druid)
  rescue ArgumentError
    flash[:error] = "Invalid DRUID: #{druid}"
    render status: 400, text: flash[:error] and return
  rescue ActiveFedora::ObjectNotFoundError # => e
    flash[:error] = 'Object does not exist in Fedora.'
    render status: 404, text: flash[:error] and return
  end

  def current_user
    cur_user = nil
    if webauth && webauth.logged_in?
      cur_user = User.find_or_create_by_webauth(webauth)
    elsif request.env['REMOTE_USER']
      cur_user = User.find_or_create_by_remoteuser(request.env['REMOTE_USER'])
    end

    if cur_user && session[:groups]
      cur_user.set_groups_to_impersonate session[:groups]
    end

    cur_user
  end

  def current_or_guest_user
    current_user
  end

  def user_session
    session
  end

  def default_html_head
    stylesheet_links << ['argo']
  end

  protected

  def munge_parameters
    case request.content_type
    when 'application/xml', 'text/xml'
      help.merge_params(Hash.from_xml(request.body.read))
    when 'application/json', 'text/json'
      help.merge_params(JSON.parse(request.body.read))
    end
  end

  def fedora_setup
    Dor::Config.fedora.post_config
  end

  def development_only!
    if Rails.env.development? || ENV['DOR_SERVICES_DEBUG_MODE']
      yield
    else
      render :text => 'Not Found', :status => :not_found
    end
  end

  def authorize!
    return true if current_user
    render nothing: true, status: :unauthorized
    false
  end

  ##
  # A ported over Rails 5 enhancement to ActionPack
  # @see https://github.com/rails/rails/commit/13fd5586cef628a71e0e2900820010742a911099
  def redirect_back(fallback_location:, **args)
    if (referer = request.headers['Referer'])
      redirect_to referer, **args
    else
      redirect_to fallback_location, **args
    end
  end

end
