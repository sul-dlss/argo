module WorkflowHelper
  def show_workflow_grid?
    controller_name == 'report' && action_name == 'workflow_grid'
  end

  def render_workflow_grid
    workflow_data = facet_tree('wf_wps')['wf_wps_ssim']
    return '' if workflow_data.nil?
    workflow_data.keys.sort.collect do |wf_name|
      render :partial => 'workflow_table', :locals => { :wf_name => wf_name, :wf_data => workflow_data[wf_name] }
    end.join("\n").html_safe
  end

  def render_workflow_name(name)
    new_params = add_facet_params("wf_wps_ssim", name).merge(:controller => 'catalog', :action => 'index')
    link_to(name, new_params)
  end

  def render_workflow_process_name(name,process)
    new_params = add_facet_params("wf_wps_ssim", [name,process].compact.join(':')).merge(:controller => 'catalog', :action => 'index')
    link_to(process, new_params)
  end

  def render_workflow_process_reset(pid, process)
    allowable_changes = {
      'hold'    => 'waiting',
      'waiting' => 'completed',
      'error'   => 'waiting'
    }
    new_status = allowable_changes[process.status]
    return '' unless new_status.present?
    form_tag workflow_update_item_url(pid, process.workflow) do
      hidden_field_tag('process', process.name) +
      hidden_field_tag('status', new_status) +
      hidden_field_tag('repo', @repo)+
      button_tag('set to ' + new_status, :type => 'submit')
    end
  end

  def render_workflow_reset_link(wf_hash, name, process, status)
    return unless (wf_hash[process] && wf_hash[process][status] && wf_hash[process][status][:_])
    new_params = add_facet_params("wf_wps_ssim", [name,process,status].compact.join(':')).merge(:controller => 'report', :action => 'reset', :reset_workflow=>name,:reset_step=>process)
    raw " | " + link_to('reset', new_params,:remote=>true)
  end

  def render_workflow_item_count(wf_hash, name, process, status)
    new_params = add_facet_params("wf_wps_ssim", [name,process,status].compact.join(':')).merge(:controller => 'catalog', :action => 'index')
    rotate_facet_params('wf_wps', 'wps', facet_order('wf_wps'), new_params)
    item_count = 0
    if wf_hash[process] && wf_hash[process][status] && item = wf_hash[process][status][:_]
      item_count = item.hits
    end
    if item_count == 0
      item_count = content_tag :span, item_count, :class => "zero"
    end
    link_to(item_count, new_params)
  end

  def render_workflow_archive_count(repo, name)
    query_results = Dor::SearchService.query("objectType_ssim:workflow title_tesim:#{name}")
    if query_results
      wf_doc = query_results.docs.first
      if wf_doc && wf_doc["#{name}_archived_isi"]
        return wf_doc["#{name}_archived_isi"]
      end
    end

    return '-'
  end

  def proc_names_for_wf(wf_name, wf_data)
    proc_names = wf_data.keys.delete_if { |k,v| !k.is_a?(String) }
    wf = Dor::WorkflowObject.find_by_name(wf_name)
    if wf.nil?
      proc_names = ActiveSupport::OrderedHash[*(proc_names.sort.collect { |n| [n,nil] }.flatten)]
    else
      proc_names = ActiveSupport::OrderedHash[*(wf.definition.processes.collect { |p| [p.name,p.label] }.flatten)]
    end
    proc_names
  end

end
