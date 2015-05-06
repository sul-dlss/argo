# Overrides for Blacklight helpers

module ArgoHelper
  include BlacklightHelper
  include ValueHelper

  def build_solr_request_from_response
    qs = @response['responseHeader']['params'].reject { |k,v| k == 'wt' }.collect do |k,v|
      v.is_a?(Array) ? v.collect { |v1| [k,URI.encode(v1.to_s)].join('=') } : [k,URI.encode(v.to_s)].join('=')
    end.flatten.join('&')
    Dor::SearchService.solr.uri.merge("select?#{qs}").to_s.html_safe
  end

  def ensure_current_document_version
    if @document.get('index_version_t').to_s < Dor::SearchService.index_version
      Dor::SearchService.reindex(@document.get('id'))
      @response, @document = get_solr_response_for_doc_id
    end
  end

  def index_queue_depth
    begin
      if Dor::Config.status and Dor::Config.status.indexer_url
        url = Dor::Config.status.indexer_url
        resp = RestClient::Request.execute(:method => :get, :url => url, :timeout => 3, :open_timeout => 3)
        data = JSON.parse(resp)
        count = data.first['datapoints'].first.first.to_i
      else
        return 0
      end
    rescue
      return 0
    end
  end

  def index_queue_velocity
    begin
      if Dor::Config.status and Dor::Config.status.indexer_velocity_url
        url=Dor::Config.status.indexer_velocity_url
        data=JSON.parse(open(url).read)
        points=[]
        data.first['datapoints'].each do |data|
          points << data.first.to_i
        end
        if points.length>1
          diff=points.last-points.first
          speed=diff/(points.length-1)
          return speed
        end
      else
        return 0
      end
    rescue
      return 0
    end
  end


  def structure_from_solr(solr_doc, prefix, suffix='display')
    prefixed_fields = Hash[solr_doc.select { |k,v| k =~ /^#{prefix}_\d+_.+_#{suffix}$/ }]
    result = Confstruct::HashWithStructAccess.new
    prefixed_fields.each_pair do |path_str,value|
      h = result
      path = path_str.sub(/_[^_]+$/,'').reverse.split(/_(?=\d+)/).collect { |k| k.reverse }.reverse.collect { |k| k.split(/_(?=\d+)/) }
      path.each do |step, index|
        if index.nil?
          h[step.to_sym] = value
        else
          h[step.to_sym] ||= []
          h = h[step.to_sym][index.to_i] ||= Confstruct::HashWithStructAccess.new
        end
      end
    end
    result
  end
  def create_rsolr_facet_field_response_for_query_facet_field facet_name, facet_field
    salient_facet_queries = facet_field.query.map { |k, x| x[:fq] }
    items = []
    @response.facet_queries.select { |k,v| salient_facet_queries.include?(k) }.reject { |value, hits| hits == 0 }.map do |value,hits|
      key = facet_field.query.select { |key, val| val[:fq] == value }.first.first
      items << OpenStruct.new(:value => key, :hits => hits, :label => facet_field.query[key][:label])
    end

    RSolr::Ext::Response::Facets::FacetField.new facet_name, items
  end


  def render_index_field_value args
    handler = "value_for_#{args[:field]}".to_sym
    if respond_to?(handler)
      send(handler, args)
    else
      super(args)
    end
  end

  def link_to_previous_document(previous_document)
    if previous_document
      link_to raw(t('views.pagination.previous')), previous_document, :class => "previous", :'data-counter' => session[:search][:counter].to_i - 1
    else
      content_tag :span, raw(t('views.pagination.previous')), :class => 'disabled'
    end
  end

  def link_to_next_document(next_document)
    if next_document
      link_to raw(t('views.pagination.next')), next_document, :class => "next", :'data-counter' => session[:search][:counter].to_i + 1
    else
      content_tag :span, raw(t('views.pagination.next')), :class => 'disabled'
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
    if doc['first_shelved_image_display']
      fname = doc['first_shelved_image_display'].first
      if fname
        druid = doc['id'].to_s.split(/:/).last
        fname = File.basename(fname,File.extname(fname))
        image_tag "#{Argo::Config.urls.stacks}/#{druid}/#{fname}_thumb", :class => 'document-thumb', :alt => '', :style=>'max-width:240px;max-height:240px;'
      end
    end
  end

  def render_index_thumbnail doc
    if doc['first_shelved_image_display']
      fname = doc['first_shelved_image_display'].first
      if fname
        druid = doc['id'].to_s.split(/:/).last
        fname = File.basename(fname,File.extname(fname))
        image_tag "#{Argo::Config.urls.stacks}/#{druid}/#{fname}_thumb", :class => 'index-thumb', :alt => '', :style=>'max-width:80px;max-height:80px;'
      end
    end
  end
  #override blacklight so apo and collection facets list title rather than druid. This will go away when we modify the index to include title with druid
  def render_facet_value(facet_solr_field, item, options ={})
    display_value = item.value =~ /druid:/ ? label_for_druid(item.value) : item.value
    (link_to_unless(options[:suppress_link], ((item.label if item.respond_to?(:label)) || display_value), add_facet_params_and_redirect(facet_solr_field, item.value), :class=>"facet_select label") + " " + render_facet_count(item.hits)).html_safe
  end

  def render_document_sections(doc, action_name)
    dor_object = @obj #Dor.find doc['id'].to_s, :lightweight => true
    format = document_partial_name(doc)
    sections = blacklight_config[:show][:sections][format.to_sym] || blacklight_config[:show][:sections][:default]
    result = ''
    sections.each_with_index do |section_name,index|
      result += render(:partial=>"catalog/_#{action_name}_partials/section", :locals=>{:document=>doc, :object=>dor_object, :format=>format, :section=>section_name, :collapsible=>(index > 0)})
    end
    return result.html_safe
  end

  def render_buttons(doc, object=nil)
    pid=doc['id']
    if not object
      object = Dor.find(pid)
    end
    apo_pid = ''
    #wf_stuff.include? 'accessionWF:completed:publish'
    begin
      apo_pid=doc['is_governed_by_s'].first.gsub('info:fedora/','')
    rescue
    end
    buttons=[]
    if(pid and can_close_version?(pid))
      buttons << {:url => '/items/'+pid+'/close_version_ui', :label => 'Close Version'}
    else
      if pid and can_open_version?(pid)
        buttons << {:url => '/items/'+pid+'/open_version_ui', :label => 'Open for modification'}
      end
    end


    #if this is an apo and the user has permission for the apo, let them edit it.
    if (object.datastreams.include? 'roleMetadata') and (current_user.is_admin or current_user.is_manager or object.can_manage_item?(current_user.roles(apo_pid)))
      buttons << {:url => url_for(:controller => :apo, :action => :register, :id => pid), :label => 'Edit APO', :new_page => true}
      buttons << {:url => url_for(:controller => :apo, :action => :register_collection, :id => pid), :label => 'Create Collection', :new_page => true}
    end
    if object.can_manage_item?(current_user.roles(apo_pid)) or current_user.is_admin or current_user.is_manager
      buttons << {:url => url_for(:controller => :dor,:action => :reindex, :pid => pid), :label => 'Reindex'}
      buttons << {:url => url_for(:controller => :items,:action => :add_workflow, :pid => pid), :label => 'Add Workflow'}
      if has_been_published? pid
        buttons << {:url => url_for(:controller => :dor,:action => :republish, :pid => pid), :label => 'Republish'}
      end
      if not has_been_submitted? pid
        buttons << {:url =>  url_for(:controller => :items,:action => :purge_object, :id => pid), :label => 'Purge', :new_page=> true, :confirm => 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?'}
      end
      buttons << {:url => '/items/'+pid+'/source_id_ui', :label => 'Change source id'}
      buttons << {:url => '/items/'+pid+'/tags_ui', :label => 'Edit tags'}
      if not (object.datastreams.include? 'administrativeMetadata') #apos cant be members of collections
        buttons << {:url => url_for(:controller => :items, :action => :collection_ui, :id => pid), :label => 'Edit collections'}
      end
      if object.datastreams.include? 'contentMetadata'
        buttons << {:url => url_for(:controller => :items, :action => :content_type, :id => pid), :label => 'Set content type'}
      end
      if object.datastreams.include? 'rightsMetadata'
        buttons << {:url => url_for(:controller => :items, :action => :rights, :id => pid), :label => 'Set rights'}
      end
      if object.datastreams.include? 'descMetadata' and object.datastreams['descMetadata'].new? == false and object.datastreams['identityMetadata'].otherId('catkey)').length == 0 and object.datastreams['identityMetadata'].otherId('mdtoolkit)').length == 0
        buttons << {:url => url_for(:controller => :items, :action => :mods, :id => pid), :label => 'Edit MODS', :new_page => true}
      end
    end
    if(doc.has_key?('embargoMetadata_t') || doc.has_key?('embargoMetadata_status_t'))
      embargo_data=doc['embargoMetadata_t'] ? doc['embargoMetadata_t'] : doc['embargoMetadata_status_t']
      text=embargo_data.split.first
      date=embargo_data.split.last
      if text != 'released'
        #add a date picker and button to change the embargo date for those who should be able to.
        buttons << {:label => 'Update embargo', :url => embargo_form_item_path(pid)} if current_user.is_admin
      end
    end
    buttons
  end

  def first_image(a)
    Array(a).find{|f| File.extname(f)=~ /jp2/}
  end

  def render_date_pickers(field_name)
    if field_name =~ /_date/
      render(:partial => 'catalog/_show_partials/date_choice', :locals => {:field_name => field_name})
    end
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
  def render_dpg_link document
    val = document.get('id').split(/:/).last
    link_to "DPG Object Status", File.join(Argo::Config.urls.dpg, val)
  end

  def render_purl_link document, link_text='PURL', opts={:target => '_blank'}
    val = document.get('id').split(/:/).last
    link_to link_text, File.join(Argo::Config.urls.purl, val), opts
  end

  def render_dor_link document, link_text='Fedora UI', opts={:target => '_blank'}
    val = document.get('id')
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{val}"), opts
  end

  def render_foxml_link document, link_text='FoXML', opts={:target => '_blank'}
    val = document.get('id')
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
    section_header_method = blacklight_config[:show][:section_links][section]
    unless section_header_method.nil?
      self.send(section_header_method, document)
    end
  end

  def render_full_dc_link document, link_text="View full Dublin Core"
    link_to link_text, dc_aspect_view_catalog_path(document.get('id')), :class => 'dialogLink', :title => 'Dublin Core (derived from MODS)'
  end
  def render_mods_view_link document, link_text="View MODS"
    link_to link_text, purl_preview_item_url(document.get('id')),:class => 'dialogLink', :title => 'MODS View'
  end
  def render_full_view_links document
    render_full_dc_link(document) + ' / '+render_mods_view_link(document)
  end

  def render_dor_workspace_link document, link_text="View DOR workspace"
  end

end
