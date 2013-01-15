module Argo
  module AccessControlsEnforcement
    extend ActiveSupport::Concern

    def add_access_controls_to_solr_params(solr_parameters, user)
      apply_gated_discovery(solr_parameters, @user)
    end

    def apply_gated_discovery(solr_parameters, user)
      #repository wide admin and viewer users shouldnt be restricted in any way
      if user.is_admin or user.is_viewer
        return solr_parameters
      end
      solr_parameters[:fq] ||= []
      pids=user.permitted_apos 
      #do this as a negative query, exclude items they dont have permission rather than including items they have permission to view
      if pids.length>20
        resp = Dor::SearchService.query('objectType_facet:adminPolicy', {:rows => 100, :fl => 'id'})['response']['docs']
        all_apos=[]
        resp.each do |doc|
          all_apos << doc['id']
        end
        disallowed_apos=all_apos-pids
        if disallowed_apos.length==0
          pids='dummy'
        else
          pids=disallowed_apos.join(" ").gsub('druid', 'info:fedora/druid').gsub(':','\:')
        end
        solr_parameters[:fq] << "is_governed_by_s:['' TO *] AND -is_governed_by_s:("+pids+")"
      else
        if pids.length == 0
          #they arent supposed to see anything, use a dummy value to make sure the solr query is valid
          pids='dummy_value'
        else
          pids=pids.join(" ").gsub('druid', 'info:fedora/druid').gsub(':','\:')
        end
        solr_parameters[:fq] << "is_governed_by_s:("+pids+")"
      end
      logger.debug("Solr parameters: #{ solr_parameters.inspect }")
      solr_parameters
    end
  end
end
