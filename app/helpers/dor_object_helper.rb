module DorObjectHelper
  # Metadata helpers
  def retrieve_terms doc
    terms = {
      :creator   => { :selector => ['public_dc_creator_t', 'mods_creator_t', 'mods_name_t', 'dc_creator_t'] },
      :title     => { :selector => ['public_dc_title_t', 'mods_title_t', 'dc_title_t', 'obj_label_t'], :combiner => lambda { |s| s.join(' -- ') } },
      :place     => { :selector => ['mods_originInfo_place_placeTerm_t'] },
      :publisher => { :selector => ['public_dc_publisher_t', 'mods_originInfo_publisher_t', 'dc_publisher_t'] },
      :date      => { :selector => ['public_dc_date_t', 'mods_dateissued_t', 'mods_datecreated_t', 'dc_date_t'] }
    }
    result = {}
    terms.each_pair do |term,finder|
      finder[:selector].each do |key|
        if doc[key].present?
          val = doc[key]
          com = finder[:combiner]
          result[term] = com ? com.call(val) : val.first
          break
        end
      end
    end
    result
  end
  
  def render_citation doc
    terms = retrieve_terms(doc)
    result = ''
    result += "#{h terms[:creator]} " if terms[:creator].present?
    result += "<em>#{h terms[:title]}</em>"
    origin_info = terms.values_at(:publisher, :place, :date).compact.join(', ')
    result += ": #{h origin_info}" if origin_info.present?
    result.html_safe
  end
  
  def render_item_status doc
    current_milestone = Array(doc['lifecycle_t']).last
    if current_milestone.nil?
      nil
    else
      status = current_milestone.split(/:/,2).first
      if embargo_status = doc['embargo_status_t']
        status += " (#{embargo_status.first})"
      end
      status
    end
  end
  
  def render_datetime(datetime)
    if datetime.nil?
      ''
    else
      d = datetime.is_a?(Time) ? datetime : Time.parse(datetime.to_s)
      d.strftime('%Y-%m-%d %I:%M%p')
    end
  end
  
  def render_events doc, obj
    events = structure_from_solr(doc,'event')
    unless events.empty?
      events = events.event.collect do |event|
        { :when => render_datetime(event.when), :who => event.who, :what => event.message }
      end
    end
    render :partial => 'catalog/_show_partials/events', :locals => { :document => doc, :object => obj, :events => events }
  end
  
  def render_milestones doc, obj
    milestones = ActiveSupport::OrderedHash[
      'registered',  { :display => 'Registered',  :time => 'pending' },
      'submitted',   { :display => 'Submitted',   :time => 'pending' },
      'described',   { :display => 'Described',   :time => 'pending' },
      'inprocess',   { :display => 'In Process',  :time => 'pending' },
      'released',    { :display => 'Released',    :time => 'pending' },
      'published',   { :display => 'Published',   :time => 'pending' },
      'archived',    { :display => 'Archived',    :time => 'pending' },
      'accessioned', { :display => 'Accessioned', :time => 'pending' }
    ]
    
    lifecycle_field = doc.has_key?('lifecycle_display') ? 'lifecycle_display' : 'lifecycle_facet'
    Array(doc[lifecycle_field]).each do |m| 
      (name,time) = m.split(/:/,2)
      milestones[name] ||= { :display => name.titleize, :time => 'pending' }
      milestones[name][:time] = render_datetime(time)
    end
    render :partial => 'catalog/_show_partials/milestones', :locals => { :document => doc, :object => obj, :milestones => milestones }
  end
  
  def render_workflows doc, obj
    workflows = {}
    Array(doc[ActiveFedora::SolrService.solr_name('workflow_status', :string, :displayable)]).each do |line|
      (wf,status,errors) = line.split(/\|/)
      workflows[wf] = { :status => status, :errors => errors.to_i }
    end
    render :partial => 'catalog/_show_partials/workflows', :locals => { :document => doc, :object => obj, :workflows => workflows }
  end
  
  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }
  def parse_specs spec_string
    Hash[[:dsid,:control_group,:mime_type,:version,:size,:label].zip(spec_string.split(/\|/))]
  end
  
  def render_ds_control_group doc, specs
    cg = specs[:control_group] || 'X'
    "#{cg}/#{CONTROL_GROUP_TEXT[cg]}"
  end
  
  def render_ds_id doc, specs
    link_to specs[:dsid], ds_aspect_view_catalog_path(doc['id'], specs[:dsid]), :class => 'dialogLink', :title => specs[:dsid]
  end
  
  def render_ds_mime_type doc, specs
    specs[:mime_type]
  end
  
  def render_ds_version doc, specs
    "v#{specs[:version]}"
  end
  
  def render_ds_size doc, specs
    val = specs[:size].to_i.bytestring('%.1f%s').downcase
    val.sub(/\.?0+([a-z]?b)$/,'\1')
  end
  
  def render_ds_label doc, specs
    specs[:label]
  end

  def render_ds_profile_header ds
    dscd = ds.createDate
    if dscd.is_a?(Time)
      dscd = dscd.xmlschema
    end
    %{<foxml:datastream ID="#{ds.dsid}" STATE="#{ds.state}" CONTROL_GROUP="#{ds.controlGroup}" VERSIONABLE="#{ds.versionable}">\n  <foxml:datastreamVersion ID="#{ds.dsVersionID}" LABEL="#{ds.label}" CREATED="#{dscd}" MIMETYPE="#{ds.mimeType}">}
  end
  
end
