require 'time' 
module Dor  
  module Editable
    def agreement=(val)
      self.agreement_object = Dor::Item.find(val.to_s)
    end
  end
  module Workflow
    class Document
      include SolrDocHelper

      def to_solr(solr_doc=Hash.new, *args)
        wf_name = self.workflowId.first
        repo=self.repository.first
        add_solr_value(solr_doc, 'wf', wf_name, :string, [:facetable])
        add_solr_value(solr_doc, 'wf_wps', wf_name, :string, [:facetable])
        add_solr_value(solr_doc, 'wf_wsp', wf_name, :string, [:facetable])
        status = processes.empty? ? 'empty' : (processes.all?(&:completed?) ? 'completed' : 'active')
        errors = processes.select(&:error?).count
        add_solr_value(solr_doc, 'workflow_status', [wf_name,status,errors,repo].join('|'), :string, [:displayable])

        processes.each do |process|
          if process.status.present?
            #add a record of the robot having operated on this item, so we can track robot activity
            if process.date_time and process.status and (process.status == 'completed' || process.status == 'error')
              add_solr_value(solr_doc, "wf_#{wf_name}_#{process.name}", process.date_time+'Z', :date)
            end
            add_solr_value(solr_doc, 'wf_error', "#{wf_name}:#{process.name}:#{process.error_message}", :string, [:facetable,:displayable]) if process.error_message #index the error message without the druid so we hopefully get some overlap
            add_solr_value(solr_doc, 'wf_wsp', "#{wf_name}:#{process.status}", :string, [:facetable])
            add_solr_value(solr_doc, 'wf_wsp', "#{wf_name}:#{process.status}:#{process.name}", :string, [:facetable])
            add_solr_value(solr_doc, 'wf_wps', "#{wf_name}:#{process.name}", :string, [:facetable])
            add_solr_value(solr_doc, 'wf_wps', "#{wf_name}:#{process.name}:#{process.status}", :string, [:facetable])
            add_solr_value(solr_doc, 'wf_swp', "#{process.status}", :string, [:facetable])
            add_solr_value(solr_doc, 'wf_swp', "#{process.status}:#{wf_name}", :string, [:facetable])
            add_solr_value(solr_doc, 'wf_swp', "#{process.status}:#{wf_name}:#{process.name}", :string, [:facetable])
            if process.state != process.status
              add_solr_value(solr_doc, 'wf_wsp', "#{wf_name}:#{process.state}:#{process.name}", :string, [:facetable])
              add_solr_value(solr_doc, 'wf_wps', "#{wf_name}:#{process.name}:#{process.state}", :string, [:facetable])
              add_solr_value(solr_doc, 'wf_swp', "#{process.state}", :string, [:facetable])
              add_solr_value(solr_doc, 'wf_swp', "#{process.state}:#{wf_name}", :string, [:facetable])
              add_solr_value(solr_doc, 'wf_swp', "#{process.state}:#{wf_name}:#{process.name}", :string, [:facetable])
            end
          end
        end

        solr_doc['wf_wps_facet'].uniq!    if solr_doc['wf_wps_facet']
        solr_doc['wf_wsp_facet'].uniq!    if solr_doc['wf_wsp_facet']
        solr_doc['wf_swp_facet'].uniq!    if solr_doc['wf_swp_facet']
        solr_doc['workflow_status'].uniq! if solr_doc['workflow_status']

        solr_doc
      end
    end
  end
end

