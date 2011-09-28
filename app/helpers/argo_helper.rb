# Overrides for Blacklight helpers
 
module ArgoHelper

  # TODO: Remove this after all documents are reindexed with id instead of PID
  def render_document_index_label *args
    super(*args).to_s
  end
  
  def get_search_results *args
    (solr_response, document_list) = super(*args)
    document_list.each do |doc|
      unless doc.has_key?(Blacklight.config[:index][:show_link])
        doc[Blacklight.config[:index][:show_link]] = doc['PID']
        silently { Dor::Item.touch doc['PID'].to_s }
      end
    end
    return [solr_response, document_list]
  end
  
  def render_index_field_value args
    if args[:field] == 'PID'
      val = args[:document].get(args[:field])
      link_to val, File.join(Dor::Config.fedora.safeurl, "objects/#{val}"), :class => 'ext-link', :target => 'dor', :title => 'View in DOR'
    else
      super(args)
    end
  end
  
  def render_document_show_field_value args
    if args[:field] == 'PID'
      val = args[:document].get(args[:field])
      link_to val, File.join(Dor::Config.fedora.safeurl, "objects/#{val}"), :class => 'ext-link', :target => 'dor', :title => 'View in DOR'
    else
      super(args)
    end
  end
  
  def render_document_class(document = @document)
#    result = super(document)
#    if document['shelved_content_file_field']
#      result += " has-thumbnail"
#    end
#    result
    "has-thumbnail"
  end
  
  def render_index_thumbnail doc
    if doc['shelved_content_file_field']
      druid = doc['id'].to_s.split(/:/).last
      fname = doc['shelved_content_file_field'].first
      fname = File.basename(fname,File.extname(fname))
      image_tag "#{Dor::Config.argo.stacks.url}/#{druid}/#{fname}_square", :class => 'index-thumb'
    end
  end
  
end
