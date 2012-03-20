module BlacklightSolrExtensions
  extend ActiveSupport::Concern
  include Blacklight::SolrHelper
  
  # TODO: Remove this after all documents are reindexed with id instead of PID
#  def render_document_index_label doc, opts
#    opts[:label] ||= render_citation(doc)
#    super(doc, opts)
#  end
  
  def add_params_to_current_search(new_params)
    p = session[:search] ? session[:search].dup : {}
    p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$

    new_params.each_pair do |field,value|
      p[:f][field] = (p[:f][field] || []).dup
      p[:f][field].push(value)
    end
    p
  end

  def add_params_to_current_search_and_redirect(params_to_add)
    new_params = add_params_to_current_search(params_to_add)

    # Delete page, if needed. 
    new_params.delete(:page)

    # Delete any request params from facet-specific action, needed
    # to redir to index action properly. 
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key| 
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index. 
    new_params[:action] = "index"
    new_params    
  end
  
  def get_search_results *args
    (solr_response, document_list) = super(*args)
    document_list.each do |doc|
      unless doc.has_key?(blacklight_config[:index][:show_link])
        doc[blacklight_config[:index][:show_link]] = doc['id']
      end
    end
    return [solr_response, document_list]
  end
  
end
