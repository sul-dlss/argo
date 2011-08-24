module WorkflowHelper
  
  def show_workflow_grid?
    not (params[:wf_grid].nil? or params[:wf_grid] == 'false')
  end
  
  def render_workflow_grid
    workflow_data = facet_tree('wf')['wf_wps_facet']
    result = workflow_data.keys.sort.collect do |wf_name|
      render :partial => 'workflow_table', :locals => { :wf_name => wf_name, :wf_data => workflow_data[wf_name] }
    end
    result.join("\n").html_safe
  end
  
  def render_workflow_item_count(wf_hash,name,process,status)
    new_params = add_facet_params("wf_wps_facet", [name,process,status].compact.join(':'))
    rotate_facet_params('wf','wps',facet_order('wf'),new_params)
    new_params[:wf_grid] = 'false'
    item_count = 0
    if wf_hash[process] && wf_hash[process][status] && item = wf_hash[process][status][:_]
      item_count = item.hits
    end
    link_to(process, new_params) + " (" + link_to(item_count, Dor::Config.workflow.url+"workflow_queue?repository=dor&workflow=#{name}&#{status}=#{process}", :target => '_blank') + ")"
  end
  
  def render_workflow_grid_toggle(field_name)
    if field_name =~ /^wf_.+_facet/
      p = params.dup
      image_path = ''
      if show_workflow_grid?
        p.delete(:wf_grid)
        img = image_tag('icons/detail_view.png', :title => "Item summary view")
      else
        p[:wf_grid] = 'true'
        img = image_tag('icons/grid_view.png', :title => "Workflow grid view")
      end
      link_to(img.html_safe, p, :class => 'no-underline')
    end
  end
  
end
