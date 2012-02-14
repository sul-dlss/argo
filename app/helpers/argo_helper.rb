# Overrides for Blacklight helpers
 
module ArgoHelper
  def ensure_current_document_version
    if @document.get('index_version_t').to_s < Dor::SearchService.index_version
      Dor::SearchService.reindex(@document.get('id'))
      @response, @document = get_solr_response_for_doc_id
    end
  end

  # TODO: Remove this after all documents are reindexed with id instead of PID
  def render_document_index_label doc, opts
    opts[:label] ||= render_citation(doc)
    super(doc, opts)
  end
  
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
      unless doc.has_key?(Blacklight.config[:index][:show_link])
        doc[Blacklight.config[:index][:show_link]] = doc['PID']
        silently { Dor::Item.touch doc['PID'].to_s }
      end
    end
    return [solr_response, document_list]
  end
  
  def render_index_field_value args
    handler = "value_for_#{args[:field]}".to_sym
    if respond_to?(handler)
      send(handler, args)
    else
      super(args)
    end
  end
  
  def render_document_heading
    ''
  end
  
  def render_show_doc_actions *args
    ''
  end
  
  def render_document_show_field_value args
    handler = "value_for_#{args[:field]}".to_sym
    if respond_to?(handler)
      send(handler, args)
    else
      super(args)
    end
  end
  
  def render_extended_document_class(document = @document)
    result = render_document_class(document).to_s
    if first_image(document['shelved_content_file_t'])
      result += " has-thumbnail"
    end
    result
  end
  
  def render_document_show_thumbnail doc
    if doc['shelved_content_file_t']
      fname = first_image(doc['shelved_content_file_t'])
      if fname
        druid = doc['id'].to_s.split(/:/).last
        fname = File.basename(fname,File.extname(fname))
        image_tag "#{Argo::Config.urls.stacks}/#{druid}/#{fname}_thumb", :class => 'document-thumb'
      end
    end
  end
  
  def render_index_thumbnail doc
    if doc['shelved_content_file_t']
      fname = first_image(doc['shelved_content_file_t'])
      if fname
        druid = doc['id'].to_s.split(/:/).last
        fname = File.basename(fname,File.extname(fname))
        image_tag "#{Argo::Config.urls.stacks}/#{druid}/#{fname}_square", :class => 'index-thumb'
      end
    end
  end
  
  def render_facet_value(facet_solr_field, item, options ={})
    display_value = item.value
    if item.value =~ /^druid:.+$/
      if ref = Reference.find(item.value)
        display_value = ref['link_text_display'].to_s
      end
    end
    (link_to_unless(options[:suppress_link], display_value, add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select label") + " " + render_facet_count(item.hits)).html_safe
  end

  def render_document_sections(doc, action_name)
    dor_object = Dor::Base.load(doc['id'].to_s, doc['objectType_t'].to_s)
    format = document_partial_name(doc)
    sections = Blacklight.config[:show][:sections][format.to_sym] || Blacklight.config[:show][:sections][:default]
    result = ''
    sections.each_with_index do |section_name,index|
      result += render(:partial=>"catalog/_#{action_name}_partials/section", :locals=>{:document=>doc,:object=>dor_object,:format=>format,:section=>section_name,:collapsible=>(index > 0)})
    end
    return result.html_safe
  end
  
  def first_image(a)
    Array(a).find { |f| Rack::Mime.mime_type(File.extname(f)) =~ /^image\// }
  end
  
  def document_has? document, field_name
    if document.has? field_name
      return true
    elsif self.respond_to?(:"calculate_#{field_name}_value")
      calculated_value = self.send(:"calculate_#{field_name}_value", document)
      if calculated_value.nil?
        return false
      else
        document[field_name] = [calculated_value] 
        return true
      end
    else
      return false
    end
  end
  
  def render_purl_link document, link_text='PURL', opts={:target => '_blank'}
    val = document.get('PID').split(/:/).last
    link_to link_text, File.join(Argo::Config.urls.purl, val), opts
  end
  
  def render_dor_link document, link_text='Fedora UI', opts={:target => '_blank'}
    val = document.get('PID')
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{val}"), opts
  end
  
  def render_foxml_link document, link_text='FoXML', opts={:target => '_blank'}
    val = document.get('PID')
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{val}/objectXML"), opts
  end
  
  def render_searchworks_link document, link_text='Searchworks', opts={:target => '_blank'}
    val = document.get('catkey_id_t')
    link_to link_text, "http://searchworks.stanford.edu/view/#{val}", opts
  end
  
  def render_mdtoolkit_link document, link_text='MD Toolkit', opts={:target => '_blank'}
    val = document.get('mdtoolkit_id_t')
    forms = JSON.parse(RestClient.get('http://lyberapps-prod.stanford.edu/forms.json'))
    form = document.get('mdform_tag_t')
    collection = forms.keys.find { |k| forms[k].keys.include?(form) }
    if form and collection
      link_to link_text, File.join(Argo::Config.urls.mdtoolkit, collection, form, 'edit', val), opts
    end
  end
  
  def render_section_header_link section, document
    section_header_method = Blacklight.config[:show][:section_links][section]
    unless section_header_method.nil?
      self.send(section_header_method, document)
    end
  end
  
  def render_full_dc_link document, link_text="View full Dublin Core"
    link_to link_text, dc_aspect_view_catalog_path(document.get('PID')), :class => 'dialogLink', :title => 'Dublin Core (derived from MODS)'
  end
  
  def render_dor_workspace_link document, link_text="View DOR workspace"
  end
  
end
