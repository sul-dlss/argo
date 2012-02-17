module HierarchyHelper

def is_hierarchical?(field_name)
  Rails.logger.info 'is_hierarchical?'
  (prefix,order,suffix) = field_name.split(/_/)
  list = blacklight_config.facet_display[:hierarchy][prefix] and list.include?(order)
end
    
def facet_order(prefix)
  param_name = "#{prefix}_facet_order".to_sym
  params[param_name] || blacklight_config.facet_display[:hierarchy][prefix].first
end

def facet_after(prefix, order)
  orders = blacklight_config.facet_display[:hierarchy][prefix]
  orders[orders.index(order)+1] || orders.first
end

def hide_facet?(field_name)
  if is_hierarchical?(field_name)
    prefix = field_name.split(/_/).first
    field_name != "#{prefix}_#{facet_order(prefix)}_facet"
  else
    false
  end
end

def rotate_facet_value(val, from, to)
  components = Hash[from.split(//).zip(val.split(/:/))]
  new_values = components.values_at(*(to.split(//)))
  while new_values.last.nil?
    new_values.pop
  end
  if new_values.include?(nil)
    nil
  else
    new_values.compact.join(':')
  end
end

def rotate_facet_params(prefix, from, to, p=params.dup)
  return p if from == to
  from_field = "#{prefix}_#{from}_facet"
  to_field = "#{prefix}_#{to}_facet"
  p[:f] = (p[:f] || {}).dup # the command above is not deep in rails3, !@#$!@#$
  p[:f][from_field] = (p[:f][from_field] || []).dup
  p[:f][to_field] = (p[:f][to_field] || []).dup
  p[:f][from_field].reject! { |v| p[:f][to_field] << rotate_facet_value(v, from, to); true }
  p[:f].delete(from_field)
  p[:f][to_field].compact!
  p[:f].delete(to_field) if p[:f][to_field].empty?
  p
end

def render_facet_rotate(field_name)
  if is_hierarchical?(field_name)
    (prefix,order,suffix) = field_name.split(/_/)
    new_order = facet_after(prefix,order)
    new_params = rotate_facet_params(prefix,order,new_order)
    new_params["#{prefix}_facet_order"] = new_order
    link_to image_tag('icons/rotate.png', :title => new_order.upcase).html_safe, new_params, :class => 'no-underline'
  end
end

def render_hierarchy(field)
  prefix = field.field.split(/_/).first
  tree = facet_tree(prefix)[field.field]
  tree.keys.sort.collect do |key|
    render :partial => 'facet_hierarchy_item', :locals => { :field_name => field.field, :data => tree[key], :key => key }
  end
end

def render_qfacet_value(facet_solr_field, item, options ={})    
  (link_to_unless(options[:suppress_link], item.value, add_facet_params_and_redirect(facet_solr_field, item.qvalue), :class=>"facet_select label") + " " + render_facet_count(item.hits)).html_safe
end

# Standard display of a SELECTED facet value, no link, special span
# with class, and 'remove' button.
def render_selected_qfacet_value(facet_solr_field, item)
  content_tag(:span, render_facet_value(facet_solr_field, item, :suppress_link => true), :class => "selected label") + " " +
    link_to("[X]", remove_facet_params(facet_solr_field, item.qvalue, params), :class=>"remove")
end

HierarchicalFacetItem = Struct.new :qvalue, :value, :hits
def facet_tree(prefix)
  @facet_tree ||= {}
  if @facet_tree[prefix].nil?
    @facet_tree[prefix] = {}
    blacklight_config.facet_display[:hierarchy][prefix].each { |key|
      facet_field = [prefix,key,'facet'].compact.join('_')
      @facet_tree[prefix][facet_field] ||= {}
      data = @response.facet_by_field_name(facet_field)
      data.items.each { |facet_item|
        path = facet_item.value.split(/\s*:\s*/)
        loc = @facet_tree[prefix][facet_field]
        while path.length > 0
          loc = loc[path.shift] ||= {}
        end
        loc[:_] = HierarchicalFacetItem.new(facet_item.value, facet_item.value.split(/\s*:\s*/).last, facet_item.hits)
      }
    }
  end
  @facet_tree[prefix]
end

end