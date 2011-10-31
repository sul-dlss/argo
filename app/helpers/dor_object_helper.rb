module DorObjectHelper
  def get_dor_object(pid)
    @dor_object_cache ||= {}
    @dor_object_cache[pid] ||= Dor::Base.load_instance(pid)
  end
  
  # Metadata helpers
  def render_citation doc
    creator = Array(doc['dc_creator_field'] || doc['mods_creator_field'] || doc['mods_name_field']).first
    title = Array(doc['dc_title_field'] || doc['mods_titleInfo_field'] || doc['fgs_label_field']).first
    place = Array(doc['mods_origininfo_place_field']).first
    publisher = Array(doc['dc_publisher_field'] || doc['mods_publisher_field']).first
    date = Array(doc['dc_date_field'] || doc['mods_dateissued_field'] || doc['mods_datecreated_field']).first
    
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
  
  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }
  def render_ds_control_group ds
    cg = ds.attributes[:controlGroup] || 'X'
    "#{cg}/#{CONTROL_GROUP_TEXT[cg]}"
  end
  
  def render_ds_id ds
    link_to ds.dsid, datastream_view_catalog_path(ds.pid, ds.dsid), :class => 'xmlLink'
  end
  
  def render_ds_mime_type ds
    ds.attributes['mimeType']
  end
  
  def render_ds_version ds
    "v0"
  end
  
  def render_ds_label ds
    ds.label
  end
  
end
