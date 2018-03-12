# Overrides for Blacklight helpers

module ArgoHelper
  include BlacklightHelper
  include ValueHelper

  def structure_from_solr(solr_doc, prefix, suffix = 'display')
    prefixed_fields = Hash[solr_doc.to_h.select { |k, v| k =~ /^#{prefix}_\d+_.+_#{suffix}$/ }]
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

  def get_thumbnail_info(doc)
    fname = doc['first_shelved_image_ss']
    return nil unless fname
    fname = File.basename(fname, File.extname(fname))
    druid = doc['id'].to_s.split(/:/).last
    url = "#{Settings.STACKS_URL}/iiif/#{druid}%2F#{ERB::Util.url_encode(fname)}/full/!400,400/0/default.jpg"
    {:fname => fname, :druid => druid, :url => url}
  end

  def render_thumbnail_helper(doc, thumb_class = '', thumb_alt = '', thumb_style = 'max-width:240px;max-height:240px;')
    thumbnail_info = get_thumbnail_info(doc)
    return nil unless thumbnail_info
    thumbnail_url = thumbnail_info[:url]
    image_tag thumbnail_url, :class => thumb_class, :alt => thumb_alt, :style => thumb_style
  end

  ##
  # Ideally this method should not make calls to external services to determine
  # what buttons should be rendered. These external requests are blocking and
  # will not allow the page to load until all requests are finished.
  #
  # Instead, use the `check_url` field to specify an endpoint for what'd be a blocking request
  # to determine whether the button should be enabled.  The button will start out disabled,
  # and will be enabled (or not) depending on the response from the call out to `check_url`.
  #
  # If you can determine whether the button should be disabled based on information that's
  # already available, without making a blocking request, you can use the `disabled` field
  # to just permanantly disable the button without calling out to a `check_url`.  Note that
  # you should not need to use both fields, since use of `check_url` disables the button at
  # first anyway.
  #
  # @param [SolrDocument] doc
  # @return [Array]
  def render_buttons(doc, object = nil)
    pid = doc['id']
    object ||= Dor.find(pid)

    apo_pid = doc.apo_pid

    buttons = []
    if can?(:manage_content, object)
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

    if can?(:manage_item, object)
      if object.is_a? Dor::AdminPolicyObject
        buttons << {:url => register_apo_index_path(id: pid), :label => 'Edit APO', :new_page => true}
        buttons << {:url => register_collection_apo_path(id: pid), :label => 'Create Collection'}
      end

      buttons << {
        url: dor_reindex_path(pid: pid),
        label: 'Reindex',
        new_page: true
      }

      # note that the backend will also check can?(:manage_governing_apo, object, new_apo_id), but
      # we can't do that here, since we don't yet know what APO the user might move the object to.
      # so it's possible that the user will get this button even if there are no other APOs they're
      # allowed to move the object to.
      buttons << {
        url: set_governing_apo_ui_item_path(id: pid),
        label: 'Set governing APO',
        disabled: !object.allows_modification?
      }

      buttons << {:url => add_workflow_item_path(id: pid), :label => 'Add workflow'}

      buttons << {
        url: dor_path(pid: pid),
        label: 'Republish',
        check_url: workflow_service_published_path(pid),
        new_page: true
      }

      buttons << {
        url: purge_item_path(id: pid),
        label: 'Purge',
        new_page: true,
        confirm: 'This object will be permanently purged from DOR. This action cannot be undone. Are you sure?',
        disabled: !registered_only?(doc)
      }

      buttons << {:url => source_id_ui_item_path(id: pid), :label => 'Change source id'}
      buttons << {:url => tags_ui_item_path(id: pid), :label => 'Edit tags'}
      if [Dor::Item, Dor::Set].any? { |clazz| object.is_a? clazz } # these only apply for items, sets and collections
        buttons << {:url => catkey_ui_item_path(id: pid), :label => 'Manage catkey'}
        buttons << {:url => collection_ui_item_path(id: pid), :label => 'Edit collections'}
      end
      if object.datastreams.include? 'contentMetadata'
        buttons << {:url => item_content_type_path(item_id: pid), :label => 'Set content type'}
      end
      if object.datastreams.include? 'rightsMetadata'
        buttons << {:url => rights_item_path(id: pid), :label => 'Set rights'}
      end
      if object.datastreams.include?('identityMetadata') && object.identityMetadata.otherId('catkey').present? # indicates there's a symphony record
        buttons << {url: refresh_metadata_item_path(id: pid), label: 'Refresh descMetadata', new_page: true, disabled: !object.allows_modification?}
      end
      buttons << { url: manage_release_solr_document_path(pid), label: 'Manage release' }

      if doc.key?('embargo_status_ssim')
        embargo_data = doc['embargo_status_ssim']
        text = embargo_data.split.first
        # date=embargo_data.split.last
        if text != 'released'
          # TODO: add a date picker and button to change the embargo date for those who should be able to.
          buttons << {:label => 'Update embargo', :url => embargo_form_item_path(pid)}
        end
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

  def render_datastream_link(document)
    return unless @document.admin_policy?
    link_to 'MODS bulk loads', bulk_jobs_index_path(@document), :id => 'bulk-button', :class => 'button btn btn-primary'
  end

  protected

  def registered_only?(document)
    ['Registered', 'Unknown Status'].include?(document['processing_status_text_ssi'])
  end
end
