module ApplicationHelper
  include Rack::Webauth::Helpers

  def fedora_base
    result = URI.parse(Dor::Config.fedora.url.sub(/\/*$/,'/'))
    result.user = result.password = nil
    return result
  end
  
  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end
  
end
