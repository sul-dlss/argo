module Argo
  module AccessControlsEnforcement
    extend ActiveSupport::Concern

    def add_access_controls_to_solr_params(solr_parameters, user)
      #usr=current_user
      #usr.set_groups(["dlss:dpg-staff"])
      apply_gated_discovery(solr_parameters, @user)
    end

    def apply_gated_discovery(solr_parameters, user)
      #repository wide admin and viewer users shouldnt be restricted in any way
      if user.is_admin or user.is_viewer
        return solr_parameters
      end
      solr_parameters[:fq] ||= []
      pids=user.permitted_apos 
      if pids.length == 0
        #they arent supposed to see anything, use a dummy value to make sure the solr query is valid
        pids='dummy_value'
      else
        pids=pids.join(" OR ").gsub('druid', 'info:fedora/druid').gsub(':','\:')
      end
      solr_parameters[:fq] << "is_governed_by_s:("+pids+")"
      logger.debug("Solr parameters: #{ solr_parameters.inspect }")
      solr_parameters
    end
  end
end