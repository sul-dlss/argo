# Overrides for Blacklight helpers
 
module ArgoHelper

  # TODO: Remove this after all documents are reindexed with id instead of PID
  def render_document_index_label *args
    super(*args).to_s
  end
  
  def get_search_results(user_params = params || {}, extra_controller_params = {})
    # In later versions of Rails, the #benchmark method can do timing
    # better for us. 
    bench_start = Time.now
    
    solr_response = find(self.solr_search_params(user_params).merge(extra_controller_params))  
    document_list = solr_response.docs.collect do |doc| 
      unless doc.has_key?(Blacklight.config[:index][:show_link])
        doc[Blacklight.config[:index][:show_link]] = doc['PID']
        silently { Dor::Item.touch doc['PID'].to_s }
      end
      SolrDocument.new(doc, solr_response)
    end
    Rails.logger.debug("Solr fetch: #{self.class}#get_search_results (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
    
    return [solr_response, document_list]
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
  
end
