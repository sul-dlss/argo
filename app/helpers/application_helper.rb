module ApplicationHelper
  include Rack::Webauth::Helpers

  def application_name
    'Argo'
  end

  def fedora_base
    URI.parse(Dor::Config.fedora.safeurl.sub(/\/*$/,'/'))
  end
  
  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end

  def inflect(str,num)
    "%d %s" % [num, (num == 1 ? str.singularize : str.pluralize)]
  end
  
  protected
  
  def silently
    begin; yield; rescue; end
  end
  
end
