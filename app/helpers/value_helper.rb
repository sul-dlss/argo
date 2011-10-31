module ValueHelper

  # Calculated fields
  def calculate_item_status_field_value doc
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

  def dereference_id_field doc, relation
    if ref = Reference.find(doc["#{relation}_id_field"].to_s)
      ref['link_text_display'].to_s
    else
      nil
    end
  end
  
  def calculate_isGovernedBy_field_value doc
    dereference_id_field(doc, "isGovernedBy")
  end
  
  def calculate_isMemberOfCollection_field_value doc
    dereference_id_field(doc, "isMemberOfCollection")
  end

  # Renderers  
  def value_for_related_druid predicate, args
    target_id = args[:document].get("#{predicate}_id_field")
    target_name = args[:document].get("#{predicate}_field")
    link_to target_name, add_params_to_current_search_and_redirect("#{predicate}_id_facet" => target_id)
  end
  
  def value_for_isGovernedBy_field args
    value_for_related_druid('isGovernedBy', args)
  end

  def value_for_isMemberOfCollection_field args
    value_for_related_druid('isMemberOfCollection', args)
  end
  
  def value_for_project_tag_field args
    val = args[:document].get(args[:field])
    link_to val, add_facet_params_and_redirect("project_tag_facet", val)
  end
  
  def value_for_fgs_createdDate_date args
    val = Time.parse(args[:document].get(args[:field]))
    val.localtime.strftime '%Y.%m.%d %H:%M%p'
  end
  
  def value_for_dc_identifier_field args
    val = args[:document][args[:field]]
    Array(val).reject { |v| v == args[:document].get('id') }.sort.uniq.join(', ')
  end
  
  def value_for_tag_field args
    val = args[:document][args[:field]]
    tags = Array(val).uniq.collect do |v| 
      link_to v, add_params_to_current_search_and_redirect("tag_facet" => v) 
    end
    tags.join('<br/>').html_safe
  end

end
