module WorkflowHelper
  def show_workflow_grid?
    controller_name == 'report' and action_name == 'workflow_grid'
  end
  
  def render_workflow_grid
    workflow_data = facet_tree('wf')['wf_wps_facet']
    result = workflow_data.keys.sort.collect do |wf_name|
      render :partial => 'workflow_table', :locals => { :wf_name => wf_name, :wf_data => workflow_data[wf_name] }
    end
    result.join("\n").html_safe
  end

  def render_workflow_name(name)
    new_params = add_facet_params("wf_wps_facet", name).merge(:controller => 'catalog', :action => 'index')
    link_to(name, new_params)
  end
  
  def render_workflow_process_name(name,process)
    new_params = add_facet_params("wf_wps_facet", [name,process].compact.join(':')).merge(:controller => 'catalog', :action => 'index')
    link_to(process, new_params)
  end
  
  def render_workflow_process_reset(pid, process)
    allowable_changes = {
      'waiting' => 'completed',
      'error'   => 'waiting'
    }
    new_status = allowable_changes[process.status]
    if new_status.present?
      form_tag workflow_update_item_url(pid, process.workflow), :class => 'dialogLink' do
        hidden_field_tag('process', process.name) +
        hidden_field_tag('status', new_status) +
        button_tag(new_status, :type => 'submit')
      end
    else
      ''
    end
  end
  
  def render_workflow_item_count(wf_hash,name,process,status)
    new_params = add_facet_params("wf_wps_facet", [name,process,status].compact.join(':')).merge(:controller => 'catalog', :action => 'index')
    rotate_facet_params('wf','wps',facet_order('wf'),new_params)
    item_count = 0
    if wf_hash[process] && wf_hash[process][status] && item = wf_hash[process][status][:_]
      item_count = item.hits
    end
    if item_count == 0
      item_count = content_tag :span, item_count, :class => "zero"
    end
    link_to(item_count, new_params)
  end
  
  def render_workflow_archive_count(repo,name)
    wf_doc = Dor::SearchService.query("objectType_facet:workflow workflow_name_s:#{name}").docs.first
    wf_doc.nil? ? '-' : wf_doc["#{name}_archived_display"].first.to_i
  end
  
  def render_workflow_grid_toggle(field_name)
    if field_name =~ /^wf_.+_facet/
      p = params.dup
      img = nil
      image_path = ''
      if show_workflow_grid?
        img = image_tag('icons/detail_view.png', :title => "Item summary view")
        p.merge!(:controller => :catalog, :action => 'index')
      else
        img = image_tag('icons/grid_view.png', :title => "Workflow grid view")
        p.merge!(:controller => :report, :action => 'workflow_grid')
      end
      link_to(img.html_safe, p, :class => 'no-underline')
    end
  end
  
end
