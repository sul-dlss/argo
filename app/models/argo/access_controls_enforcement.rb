
module Argo
  module AccessControlsEnforcement
    extend ActiveSupport::Concern

    def add_access_controls_to_solr_params(solr_parameters)
      apply_gated_discovery(solr_parameters, scope.current_user)
    end

    private

    def apply_gated_discovery(solr_parameters, user)
      # repository wide admin and viewer users shouldnt be restricted in any way
      if user.is_admin || user.is_viewer || user.is_manager
        return solr_parameters
      end
      solr_parameters[:fq] ||= []
      pids = user.permitted_apos
      # do this as a negative query, exclude items they dont have permission rather than including items they have permission to view
      if pids.length == 0
        # they arent supposed to see anything, use a dummy value to make sure the solr query is valid
        pids = 'dummy_value'
      else
        new_pids = []
        pids.each do |pid|
          new_pids << '"info:fedora/' + pid + '"'
        end
        pids = new_pids
        pids = pids.join(' OR ')
      end
      solr_parameters[:fq] << "#{SolrDocument::FIELD_APO_ID}:(#{pids})"
      logger.debug("Solr parameters: #{ solr_parameters.inspect }")
      solr_parameters
    end
  end
end
