# Overrides for Blacklight helpers
 
module ArgoHelper

  # TODO: Remove this after all documents are reindexed with id instead of PID
  def render_document_index_label doc, opts
    render_citation doc
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
    if first_image(document['shelved_content_file_field'])
      result += " has-thumbnail"
    end
    result
  end
  
  def render_document_show_thumbnail doc
    if doc['shelved_content_file_field']
      fname = first_image(doc['shelved_content_file_field'])
      if fname
        druid = doc['id'].to_s.split(/:/).last
        fname = File.basename(fname,File.extname(fname))
        image_tag "#{Dor::Config.argo.stacks.url}/#{druid}/#{fname}_thumb", :class => 'document-thumb'
      end
    end
  end
  
  def render_index_thumbnail doc
    if doc['shelved_content_file_field']
      fname = first_image(doc['shelved_content_file_field'])
      if fname
        druid = doc['id'].to_s.split(/:/).last
        fname = File.basename(fname,File.extname(fname))
        image_tag "#{Dor::Config.argo.stacks.url}/#{druid}/#{fname}_square", :class => 'index-thumb'
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
    dor_object = get_dor_object(doc['id'].to_s)
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
    link_to link_text, File.join(Dor::Config.argo.purl.url, val), opts
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
    val = document.get('dor_catkey_id_field')
    link_to link_text, "http://searchworks.stanford.edu/view/#{val}", opts
  end
  
  def render_mdtoolkit_link document, link_text='MD Toolkit', opts={:target => '_blank'}
    val = document.get('dor_mdtoolkit_id_field')
    forms = JSON.parse(RestClient.get('http://lyberapps-prod.stanford.edu/forms.json'))
    form = document.get('mdform_tag_field')
    collection = forms.keys.find { |k| forms[k].keys.include?(form) }
    link_to link_text, File.join(Dor::Config.argo.mdtoolkit.url, collection, form, 'edit', val), opts
  end
  
end
