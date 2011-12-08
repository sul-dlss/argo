module DorObjectHelper
  # Metadata helpers
  def render_citation doc
    creator = Array(doc['mods_creator_field'] || doc['mods_name_field'] || doc['dc_creator_field']).first
    title = Array(doc['mods_titleInfo_field'] || doc['dc_title_field'] || doc['fgs_label_field']).first
    place = Array(doc['mods_origininfo_place_field']).first
    publisher = Array(doc['mods_publisher_field'] || doc['dc_publisher_field']).first
    date = Array(doc['mods_dateissued_field'] || doc['mods_datecreated_field'] || doc['dc_date_field']).first
    
    result = ''
    result += "#{h creator} " unless creator.nil?
    result += "<i>#{h title}</i>"
    origin_info = [publisher, place, date].compact.join(', ')
    result += ": #{h origin_info}" unless origin_info.empty?
    result.html_safe
  end
  
  def render_item_status doc
    current_milestone = Array(doc['lifecycle_field']).last
    if current_milestone.nil?
      nil
    else
      status = current_milestone.split(/:/,2).first
      if embargo_status = doc['embargo_status_field']
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
    events = []
    if obj.datastreams_in_fedora.has_key?('events')
      doc = Nokogiri::XML(obj.datastreams['events'].content)
      events = doc.xpath('//event').collect do |node|
        { :when => render_datetime(node['when']), :who => node['who'], :what => node.text }
      end
    end
    render :partial => 'catalog/_show_partials/events', :locals => { :document => doc, :object => obj, :events => events }
  end
  
  def render_milestones doc, obj
    milestones = ActiveSupport::OrderedHash[
      'registered',  { :display => 'Registered',  :time => 'pending' },
      'inprocess',   { :display => 'In Process',  :time => 'pending' },
      'released',    { :display => 'Released',    :time => 'pending' },
      'archived',    { :display => 'Archived',    :time => 'pending' },
      'accessioned', { :display => 'Accessioned', :time => 'pending' }
    ]
    
    Array(doc['lifecycle_field']).each do |m| 
      (name,time) = m.split(/:/,2)
      milestones[name][:time] = render_datetime(time)
    end
    render :partial => 'catalog/_show_partials/milestones', :locals => { :document => doc, :object => obj, :milestones => milestones }
  end
  
  def render_workflows doc, obj
    workflows = obj.workflows.inject({}) do |hash,wf_name|
      wf = obj.datastreams[wf_name]
      status = wf.processes.empty? ? 'empty' : (wf.processes.all? { |process| process.status == 'completed' } ? 'completed' : 'active')
      errors = wf.processes.select { |process| process.status == 'error' }.count
      hash[wf_name] = { :status => status, :errors => errors }
      hash
    end
    render :partial => 'catalog/_show_partials/workflows', :locals => { :document => doc, :object => obj, :workflows => workflows }
  end
  
  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }
  def render_ds_control_group ds, document
    cg = ds.attributes[:controlGroup] || 'X'
    "#{cg}/#{CONTROL_GROUP_TEXT[cg]}"
  end
  
  def render_ds_id ds, document
    link_to ds.dsid, ds_aspect_view_catalog_path(ds.pid, ds.dsid), :class => 'dialogLink', :title => ds.dsid
  end
  
  def render_ds_mime_type ds, document
    ds.attributes['mimeType']
  end
  
  def render_ds_version ds, document
    val = Array(document['fedora_datastream_version_field']).find { |v| v.split(/\./).first == ds.dsid }
    val ? "v#{val.split(/\./).last}" : ''
  end
  
  def render_ds_size ds, document
    val = ds.content.length.bytestring('%.1f%s').downcase
    val.sub(/\.?0+([a-z]?b)$/,'\1')
  end
  
  def render_ds_label ds, document
    ds.label
  end
  
end
