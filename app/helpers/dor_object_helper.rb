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

  # rubocop:disable Layout/LineLength
  def render_ds_profile_header(ds)
    dscd = ds.createDate
    dscd = dscd.xmlschema if dscd.is_a?(Time)
    %(<foxml:datastream ID="#{ds.dsid}" STATE="#{ds.state}" CONTROL_GROUP="#{ds.controlGroup}" VERSIONABLE="#{ds.versionable}">\n  <foxml:datastreamVersion ID="#{ds.dsVersionID}" LABEL="#{ds.label}" CREATED="#{dscd}" MIMETYPE="#{ds.mimeType}">)
  end
  # rubocop:enable Layout/LineLength
end
