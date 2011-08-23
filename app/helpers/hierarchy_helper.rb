module HierarchyHelper

def is_hierarchical?(field_name)
  (prefix,order,suffix) = field_name.split(/_/)
  list = Blacklight.config[:facet][:hierarchy][prefix] and list.include?(order)
end
    
def facet_order(prefix)
  param_name = "#{prefix}_facet_order".to_sym
  params[param_name] || Blacklight.config[:facet][:hierarchy][prefix].first
end

def facet_after(prefix, order)
  orders = Blacklight.config[:facet][:hierarchy][prefix]
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

def render_facet_rotate(field_name)
  if is_hierarchical?(field_name)
    (prefix,order,suffix) = field_name.split(/_/)
    new_order = facet_after(prefix,order)
    new_params = params.dup
    new_params["#{prefix}_facet_order"] = new_order
    link_to '♺', new_params
  end
end

def render_hierarchy(field)
  prefix = field.name.split(/_/).first
  facet_tree(prefix)[field.name].keys.sort.collect do |key|
    render :partial => 'facet_hierarchy_item', :locals => { :field_name => field.name, :data => facet_tree(prefix)[field.name][key] }
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
    Blacklight.config[:facet][:hierarchy][prefix].each { |key|
      facet_field = [prefix,key,'facet'].join('_')
      @facet_tree[prefix][facet_field] ||= {}
      data = @response.facet_by_field_name(facet_field)
      data.items.each { |facet_item|
        path = facet_item.value.split(/:/)
        loc = @facet_tree[prefix][facet_field]
        while path.length > 0
          loc = loc[path.shift] ||= {}
        end
        loc[:_] = HierarchicalFacetItem.new(facet_item.value, facet_item.value.split(/:/).last, facet_item.hits)
      }
    }
  end
  @facet_tree[prefix]
end

end