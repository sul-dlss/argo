module Argo
  module AccessControlsEnforcement
    extend ActiveSupport::Concern

    def add_access_controls_to_solr_params(solr_parameters, user)
      apply_gated_discovery(solr_parameters, current_user)
    end

    def apply_gated_discovery(solr_parameters, user)
      solr_parameters[:fq] ||= []
      pids=user.permitted_apos 
      pids=pids.join(" OR ").gsub('druid', 'info:fedora/druid').gsub(':','\:')
      solr_parameters[:fq] << "is_governed_by_s:("+pids+")"
      logger.debug("Solr parameters: #{ solr_parameters.inspect }")
      solr_parameters
    end
  end
end