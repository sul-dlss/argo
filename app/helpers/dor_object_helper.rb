module DorObjectHelper
  # Metadata helpers
  def retrieve_terms(doc)
    terms = {
      :creator   => { :selector => %w(public_dc_creator_tesim dc_creator_tesim) },
      :title     => { :selector => %w(public_dc_title_tesim dc_title_tesim obj_label_tesim), :combiner => lambda { |s| s.join(' -- ') } },
      :place     => { :selector => ['originInfo_place_placeTerm_tesim'] },
      :publisher => { :selector => %w(public_dc_publisher_tesim originInfo_publisher_tesim) },
      :date      => { :selector => %w(public_dc_date_tesim originInfo_date_created_tesim) }
    }
    result = {}
    terms.each_pair do |term, finder|
      finder[:selector].each do |key|
        next unless doc[key].present?
        val = doc[key]
        com = finder[:combiner]
        result[term] = com ? com.call(val) : val.first
        break
      end
    end
    result
  end

  def render_citation(doc)
    terms = retrieve_terms(doc)
    result = ''
    result += "#{terms[:creator].html_safe} " if terms[:creator].present?
    result += "<em>#{terms[:title].html_safe}</em>" if terms[:title].present?
    origin_info = terms.values_at(:publisher, :place, :date).compact.join(', ')
    result += ": #{origin_info.html_safe}" if origin_info.present?
    result.html_safe
  end

  def render_embargo_date_reset(pid, current_user)
    # new_date=Datetime.parse(new_date)
    # if(new_date.past?)
    #   raise 'The new date must be in the future!'
    # end
    if is_permitted(current_user, :modify, pid)
      form_tag embargo_update_item_url(pid) do
        button_tag('Change Embargo', :type => 'submit')
      end
    else
      ''
    end
  end

  # FIXME: XXX: Nice security there.
  def is_permitted(current_user, operation, pid)
    true
  end

  def get_dor_obj_if_exists(obj_id)
    Dor.find(obj_id)
  rescue ActiveFedora::ObjectNotFoundError # => e
    nil
  end

  def render_datetime(datetime)
    return '' if datetime.nil? || datetime == ''
    # this needs to use the timezone set in config.time_zone
    begin
      zone = ActiveSupport::TimeZone.new('Pacific Time (US & Canada)')
      d = datetime.is_a?(Time) ? datetime : DateTime.parse(datetime).in_time_zone(zone)
      I18n.l(d)
    rescue
      d = datetime.is_a?(Time) ? datetime : Time.parse(datetime.to_s)
      d.strftime('%Y-%m-%d %I:%M%p')
    end
  end

  def render_events(doc, obj)
    events = structure_from_solr(doc, 'event')
    unless events.empty?
      events = events.event.collect do |event|
        next if event.nil?
        event.who = event.who.first if event.who.is_a? Array
        event.message = event.message.first if event.message.is_a? Array
        { :when => render_datetime(event.when), :who => event.who, :what => event.message }
      end
    end
    render :partial => 'catalog/show_events', :locals => { :document => doc, :object => obj, :events => events.compact }
  end

  def render_milestones(doc, obj)
    milestones = SolrDocument.get_milestones(doc)
    version_hash = SolrDocument.get_versions(doc)
    render :partial => 'catalog/show_milestones', :locals => { :document => doc, :object => obj, :milestones => milestones, :version_hash => version_hash}
  end

  def render_status(doc, object = nil)
    object.nil? ? doc['status_ssi'] : object.status.html_safe
  end

  def render_status_style(doc, object = nil)
    unless object.nil?
      steps = Dor::Processable::STEPS
      highlighted_statuses = [steps['registered'], steps['submitted'], steps['described'], steps['published'], steps['deposited']]
      return 'argo-obj-status-highlight' if highlighted_statuses.include? object.status_info[:status_code]
    end
    ''
  end

  # Rename from 'metadata_source' to 'get_metadata_source' to avoid conflict with APO 'metadata_source'
  # @param [Dor::Item]
  # @return [String]
  def get_metadata_source(object)
    return 'Metadata Toolkit' if object.identityMetadata.otherId('mdtoolkit').length > 0
    return 'Symphony'         if object.identityMetadata.otherId('catkey').length > 0
    'DOR'
  end

  ##
  # @deprecated Please use non-blocking requests rather than blocking helpers.
  # See WorkflowServiceController#published for JSON API to this logic
  def has_been_published?(pid)
    Dor::WorkflowService.get_lifecycle('dor', pid, 'published')
  end

  ##
  # @deprecated Please use non-blocking requests rather than blocking helpers.
  # See WorkflowServiceController#submitted for JSON API to this logic
  def has_been_submitted?(pid)
    Dor::WorkflowService.get_lifecycle('dor', pid, 'submitted')
  end

  ##
  # @deprecated Please use non-blocking requests rather than blocking helpers.
  # See WorkflowServiceController#accesssioned for JSON API to this logic
  def has_been_accessioned?(pid)
    Dor::WorkflowService.get_lifecycle('dor', pid, 'accessioned')
  end

  def last_accessioned_version(object)
    Sdr::Client.current_version(object.pid)
  end

  ##
  # @deprecated Please use non-blocking requests rather than blocking helpers.
  # See WorkflowServiceController#openable for JSON API to this logic
  def can_open_version?(pid)
    return false unless Dor::WorkflowService.get_lifecycle('dor', pid, 'accessioned')
    return false if Dor::WorkflowService.get_active_lifecycle('dor', pid, 'submitted')
    return false if Dor::WorkflowService.get_active_lifecycle('dor', pid, 'opened')
    true
  end

  ##
  # @deprecated Please use non-blocking requests rather than blocking helpers.
  # See WorkflowServiceController#closeable for JSON API to this logic
  def can_close_version?(pid)
    Dor::WorkflowService.get_active_lifecycle('dor', pid, 'opened') && !Dor::WorkflowService.get_active_lifecycle('dor', pid, 'submitted')
  end

  def render_qfacet_value(facet_solr_field, item, options = {})
    params = add_facet_params(facet_solr_field, item.qvalue)
    Rails.cache.fetch('route_for' + params.to_s, :expires_in => 1.hour) do
      (link_to_unless(options[:suppress_link], item.value, params , :class => 'facet_select') + ' ' + render_facet_count(item.hits)).html_safe
    end
  end

  def render_workflows(doc, obj)
    workflows = {}
    Array(doc[ActiveFedora::SolrService.solr_name('workflow_status', :symbol)]).each do |line|
      (wf, status, errors, repo) = line.split(/\|/)
      workflows[wf] = { :status => status, :errors => errors.to_i, :repo => repo }
    end
    render :partial => 'catalog/show_workflows', :locals => { :document => doc, :object => obj, :workflows => workflows }
  end

  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }
  def parse_specs(spec_string)
    Hash[[:dsid, :control_group, :mime_type, :version, :size, :label].zip(spec_string.split(/\|/))]
  end

  def render_ds_control_group(doc, specs)
    cg = specs[:control_group] || 'X'
    "#{cg}/#{CONTROL_GROUP_TEXT[cg]}"
  end

  def render_ds_id(doc, specs)
    link_to specs[:dsid], ds_aspect_view_catalog_path(doc['id'], specs[:dsid]), :title => specs[:dsid], :data => { behavior: 'persistent-modal' }
  end

  def render_ds_mime_type(doc, specs)
    specs[:mime_type]
  end

  def render_ds_version(doc, specs)
    "v#{specs[:version]}"
  end

  def render_ds_size(doc, specs)
    number_to_human_size(specs[:size])
  end

  def render_ds_label(doc, specs)
    specs[:label]
  end

  def render_ds_profile_header(ds)
    dscd = ds.createDate
    dscd = dscd.xmlschema if dscd.is_a?(Time)
    %(<foxml:datastream ID="#{ds.dsid}" STATE="#{ds.state}" CONTROL_GROUP="#{ds.controlGroup}" VERSIONABLE="#{ds.versionable}">\n  <foxml:datastreamVersion ID="#{ds.dsVersionID}" LABEL="#{ds.label}" CREATED="#{dscd}" MIMETYPE="#{ds.mimeType}">)
  end

end
