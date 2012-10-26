module ItemsHelper
  def valid_resource_types type
    valid_types=['object','file']
    if type =~/Book/
      valid_types<<'page'
      valid_types<<'spread'
    end
    if type=~/File/
      valid_types<<'main'
      valid_types<<'supplement'
      valid_types<<'permission'
    end
    if type=~ /Image/
      valid_types<<'image'     
    end 
    return valid_types  
  end
  def stacks_url_full_size obj, file_name
    druid=obj.pid.gsub('druid:','')
    Argo::Config.urls.stacks+'/'+druid+'/'+file_name+'_full'
  end
end
