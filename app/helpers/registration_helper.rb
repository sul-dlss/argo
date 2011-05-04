# Helper methods defined here can be accessed in any controller or view in the application

RubyDorServices.helpers do

  def apo_list(search = nil)
    q = 'object_type_field:adminPolicy'
    q += " dc_title_field:#{search.downcase}*" unless search.to_s.empty?
    result = Dor::SearchService.gsearch(:q => q)['response']['docs']
    result.sort! do |a,b|
      a['tag_field'].include?('AdminPolicy : default') ? -1 : a['dc_title_field'].to_s <=> b['dc_title_field'].to_s
    end
    result.collect! do |doc|
      [doc['dc_title_field'].to_s,doc['PID'].to_s]
    end
  end
  
  def object_location(pid)
    settings.fedora_base.merge("objects/#{pid}").to_s
  end
  
  def metadata_sources
    [
      ['Symphony (catkey)','catkey'], 
      ['Symphony (barcode)','barcode'], 
      ['Metadata Toolkit (druid)','mdtoolkit'], 
      ['None (label only)','label']
    ]
  end

end