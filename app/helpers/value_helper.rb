module ValueHelper

  # Calculated fields
  def calculate_item_status_t_value doc
    current_milestone = Array(doc['lifecycle_field']).last
    if current_milestone.nil?
      nil
    else
      status = current_milestone.split(/:/,2).first
      if embargo_status = doc.get('embargo_status_field')
        status += " (#{embargo_status})"
      end
      status
    end
  end
  
  # Renderers
  def label_for_druid druid
    druid = druid.split(/\//).last # strip "info:fedora/"
    Rails.cache.fetch("label_for_#{druid}", :expires_in => 1.hour) do 
      Dor.find(druid, :lightweight => true).label rescue druid
    end
  end
  
  def value_for_related_druid predicate, args
    begin
      target_id = args[:document].get("#{predicate}_s")
      target_name = label_for_druid(target_id)
      link_to target_name, catalog_path(target_id.split(/\//).last)
    rescue Exception => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end
  end
  
  def value_for_is_governed_by_s args
    value_for_related_druid('is_governed_by', args)
  end

  def value_for_is_member_of_collection_s args
    value_for_related_druid('is_member_of_collection', args)
  end
  
  def value_for_project_tag_t args
    val = args[:document].get(args[:field])
    link_to val, add_facet_params_and_redirect("project_tag_facet", val)
  end
  
  def value_for_objProfile_objCreateDate_dt args
    val = Time.parse(args[:document][args[:field]].first)
    val.localtime.strftime '%Y.%m.%d %H:%M%p'
  end
  
  def value_for_identifier_t args
    val = args[:document][args[:field]]
    Array(val).reject { |v| v == args[:document]['id'] }.sort.uniq.join(', ')
  end
  
  def value_for_tag_t args
    val = args[:document][args[:field]]
    tags = Array(val).uniq.collect do |v| 
      link_to v, add_facet_params_and_redirect("tag_facet", v) 
    end
    tags.join('<br/>').html_safe
  end

end
