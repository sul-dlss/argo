module DorObjectHelper
  # Metadata helpers
  def render_citation doc
    creator = Array(doc['mods_creator_t'] || doc['mods_name_t'] || doc['dc_creator_t']).first
    title = Array(doc['mods_titleInfo_t'] || doc['dc_title_t'] || doc['obj_label_t']).first
    place = Array(doc['mods_originInfo_place_placeTerm_t']).first
    publisher = Array(doc['mods_originInfo_publisher_t'] || doc['dc_publisher_t']).first
    date = Array(doc['mods_dateissued_t'] || doc['mods_datecreated_t'] || doc['dc_date_t']).first
    
    result = ''
    result += "#{h creator} " if creator.present?
    result += "<em>#{h title}</em>"
    origin_info = [publisher, place, date].compact.join(', ')
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
      'inprocess',   { :display => 'In Process',  :time => 'pending' },
      'released',    { :display => 'Released',    :time => 'pending' },
      'published',   { :display => 'Published',   :time => 'pending' },
      'archived',    { :display => 'Archived',    :time => 'pending' },
      'accessioned', { :display => 'Accessioned', :time => 'pending' }
    ]
    
    Array(doc['lifecycle_facet']).each do |m| 
      (name,time) = m.split(/:/,2)
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
  
end
