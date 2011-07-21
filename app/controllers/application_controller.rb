class ApplicationController < ActionController::Base
  before_filter :unpack_webauth
  before_filter :fedora_setup
  
  include Rack::Webauth::Helpers

  attr_reader :help
  
  def initialize(*args)
    super
    
    klass_chain = self.class.name.sub(/Controller$/,'Helper').split(/::/)
    klass = Module.const_get(klass_chain.shift)
    while klass_chain.length > 0
      klass = klass.const_get(klass_chain.shift)
    end
    @help = Class.new {
      include klass
      include ApplicationHelper
    }.new
    self
  end
  
  protected
  def munge_parameters
    case request.content_type
    when 'application/xml','text/xml'
      help.merge_params(Hash.from_xml(request.body.read))
    when 'application/json','text/json'
      help.merge_params(JSON.parse(request.body.read))
    end
  end

  def fedora_setup
    Dor::Config.fedora.post_config
  end

  def unpack_webauth
    begin
      unless session[:webauth_env].nil?
        unless webauth.logged_in?
          hash = JSON.parse(session[:webauth_env])
          request.env[Rack::Webauth::NS] = Rack::Webauth::Info.new(request.env.merge(hash))
        end
      end
    rescue JSON::ParserError
    end
  end
  
  def authorize!
    unless webauth.logged_in?
      redirect_to "#{auth_login_url}?return=#{request.fullpath}" 
      return false
    end
    return true
  end

end
