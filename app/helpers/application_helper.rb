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

  def html_list(type, elements, options = {})
    if elements.empty?
      "" 
    else
      lis = elements.map { |x| content_tag("li", x, {}, false) }
      content_tag(type, lis, options, false)
    end
  end

  def ul(*args)
    html_list("ul", *args)
  end

  def ol(*args)
    html_list("ol", *args)
  end
    
end
