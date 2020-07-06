# frozen_string_literal: true

module DorObjectHelper
  def render_workflows(doc)
    workflows = {}
    Array(doc[ActiveFedora::SolrService.solr_name('workflow_status', :symbol)]).each do |line|
      (wf, status, errors) = line.split(/\|/)
      workflows[wf] = { status: status, errors: errors.to_i }
    end
    render 'catalog/show_workflows', document_id: doc.id, workflows: workflows
  end
end
