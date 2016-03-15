# Overrides for Blacklight helpers

module ArgoHelper
  include BlacklightHelper
  include ValueHelper

  def structure_from_solr(solr_doc, prefix, suffix = 'display')
    prefixed_fields = Hash[solr_doc.select { |k, v| k =~ /^#{prefix}_\d+_.+_#{suffix}$/ }]
    result = Confstruct::HashWithStructAccess.new
    prefixed_fields.each_pair do |path_str, value|
      h = result
      path = path_str.sub(/_[^_]+$/, '').reverse.split(/_(?=\d+)/).collect(&:reverse).reverse.collect { |k| k.split(/_(?=\d+)/) }
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

  def render_document_show_field_value(args)
    handler = "value_for_#{args[:field]}".to_sym
    if respond_to?(handler)
      send(handler, args)
    else
      super(args)
    end
  end

  def get_thumbnail_info(doc)
    fname = doc['first_shelved_image_ss']
    return nil unless fname
    fname = File.basename(fname, File.extname(fname))
    druid = doc['id'].to_s.split(/:/).last
    url = "#{Settings.STACKS_URL}/iiif/#{druid}%2F#{fname}/full/!400,400/0/default.jpg"
    {:fname => fname, :druid => druid, :url => url}
  end

  def render_thumbnail_helper(doc, thumb_class = '', thumb_alt = '', thumb_style = '')
    thumbnail_info = get_thumbnail_info(doc)
    return nil unless thumbnail_info
    thumbnail_url = thumbnail_info[:url]
    image_tag thumbnail_url, :class => thumb_class, :alt => thumb_alt, :style => thumb_style
  end

  def render_document_show_thumbnail(doc)
    render_thumbnail_helper doc, 'document-thumb', '', 'max-width:240px;max-height:240px;'
  end

  def render_index_thumbnail(doc, options = {})
    render_thumbnail_helper doc, 'index-thumb', '', 'max-width:240px;max-height:240px;'
  end

  def render_document_sections(doc, action_name)
    dor_object = @obj # Dor.find doc['id'].to_s, :lightweight => true
    format = document_partial_name(doc)
    sections = blacklight_config[:show][:sections][format.to_sym] || blacklight_config[:show][:sections][:default]
    result = ''
    sections.each_with_index do |section_name, index|
      result += render(:partial => "catalog/#{action_name}_section", :locals => {:document => doc, :object => dor_object, :format => format, :section => section_name, :collapsible => (index > 0)})
    end
    result.html_safe
  end

  ##
  # Ideally this method should not make calls to external services to determine
  # what buttons should be rendered. These external requests are blocking and
  # will not allow the page to load until all requests are finished.
  # @param [SolrDocument] doc
  # @return [Array]
  def render_buttons(doc, object = nil)
    pid = doc['id']
    object ||= Dor.find(pid)

    apo_pid = doc.apo_pid

    buttons = []
    if pid
      buttons << {
        url: close_version_ui_item_path(pid),
        label: 'Close Version',
        check_url: workflow_service_closeable_path(pid)
      }

      buttons << {
        url: open_version_ui_item_path(pid),
        label: 'Open for modification',
        check_url: workflow_service_openable_path(pid)
      }
    end

    # if this is an apo and the user has permission for the apo, let them edit it.
    if object.datastreams.include?('roleMetadata') && can?(:manage_item, object)
      buttons << {:url => url_for(:controller => :apo, :action => :register, :id => pid), :label => 'Edit APO', :new_page => true}
      buttons << {:url => url_for(:controller => :apo, :action => :register_collection, :id => pid), :label => 'Create Collection'}
    end
    if can?(:manage_item, object)
      buttons << {
        url: url_for(controller: :dor, action: :reindex, pid: pid),
        label: 'Reindex',
        new_page: true
      }
      buttons << {:url => url_for(:controller => :items, :action => :add_workflow, :id => pid), :label => 'Add workflow'}

      buttons << {
        url: url_for(:controller => :dor, :action => :republish, :pid => pid),
        label: 'Republish',
        check_url: workflow_service_published_path(pid),
        new_page: true
      }

      buttons << {
        url:  url_for(:controller => :items, :action => :purge_object, :id => pid),
        label: 'Purge',
        new_page: true,
        confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
        check_url: !registered_only?(doc)
      }

      buttons << {:url => '/items/' + pid + '/source_id_ui', :label => 'Change source id'}
      buttons << {:url => '/items/' + pid + '/tags_ui', :label => 'Edit tags'}
      unless object.datastreams.include? 'administrativeMetadata' # apos cant be members of collections
        buttons << {:url => url_for(:controller => :items, :action => :collection_ui, :id => pid), :label => 'Edit collections'}
      end
      if object.datastreams.include? 'contentMetadata'
        buttons << {:url => url_for(:controller => :items, :action => :content_type, :id => pid), :label => 'Set content type'}
      end
      if object.datastreams.include? 'rightsMetadata'
        buttons << {:url => url_for(:controller => :items, :action => :rights, :id => pid), :label => 'Set rights'}
      end
    end
    if doc.key?('embargo_status_ssim')
      embargo_data = doc['embargo_status_ssim']
      text = embargo_data.split.first
      # date=embargo_data.split.last
      if text != 'released'
        # TODO: add a date picker and button to change the embargo date for those who should be able to.
        buttons << {:label => 'Update embargo', :url => embargo_form_item_path(pid)} if can?(:manage_item, object)
      end
    end
    buttons
  end

  def render_purl_link(document, link_text = 'PURL', opts = {:target => '_blank'})
    link_to link_text, File.join(Settings.PURL_URL, document.druid), opts
  end

  def render_dor_link(document, link_text = 'Fedora UI', opts = {:target => '_blank'})
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{document.id}"), opts
  end

  def render_foxml_link(document, link_text = 'FoXML', opts = {:target => '_blank'})
    link_to link_text, File.join(Dor::Config.fedora.safeurl, "objects/#{document.id}/objectXML"), opts
  end

  def render_index_info(document)
    "indexed by DOR Services v#{@document.first(Dor::INDEX_VERSION_FIELD)}"
  end

  def render_searchworks_link(document, link_text = 'Searchworks', opts = {:target => '_blank'})
    link_to link_text, "http://searchworks.stanford.edu/view/#{document.catkey}", opts
  end

  def render_section_header_link(section, document)
    section_header_method = blacklight_config[:show][:section_links][section]
    return if section_header_method.nil?
    send(section_header_method, document)
  end

  def render_full_dc_link(document, link_text = 'View full Dublin Core')
    link_to link_text, dc_aspect_view_catalog_path(document.id), :title => 'Dublin Core (derived from MODS)', :data => { ajax_modal: 'trigger' }
  end

  def render_mods_view_link(document, link_text = 'View MODS')
    link_to link_text, purl_preview_item_url(document.id), :title => 'MODS View', :data => { ajax_modal: 'trigger' }
  end

  def render_full_view_links(document)
    render_full_dc_link(document) + ' / ' + render_mods_view_link(document)
  end

  def render_dor_workspace_link(document, link_text = 'View DOR workspace')
  end

  def render_datastream_link(document)
    return unless @document.admin_policy?
    link_to 'MODS bulk loads', bulk_jobs_index_path(@document), :id => 'bulk-button', :class => 'button btn btn-primary'
  end

  protected

  def registered_only?(document)
    ['Registered', 'Unknown Status'].include?(document['processing_status_text_ssi'])
  end
end
