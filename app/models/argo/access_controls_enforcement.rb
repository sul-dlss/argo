
module Argo
  module AccessControlsEnforcement
    extend ActiveSupport::Concern

    def add_access_controls_to_solr_params(solr_parameters)
      apply_gated_discovery(solr_parameters, scope.current_user)
    end

    private

    def apply_gated_discovery(solr_parameters, user)
      # Repository wide admin, manager and viewer users access everything
      return solr_parameters if user.is_admin || user.is_manager || user.is_viewer
      pids = user.permitted_apos
      # Do this as a negative query, exclude items they cannot access
      # rather than including items they can access.
      solr_pids = pids.map {|p| '"info:fedora/' + p + '"' }.join(' OR ')
      # Check for an empty set of PIDs.  If empty, they aren't supposed to see
      # anything, but use a dummy value to make sure the solr query is valid.
      solr_pids = 'dummy_value' if solr_pids.blank?
      # Initialize and/or append to :fq
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{SolrDocument::FIELD_APO_ID}:(#{solr_pids})"
      solr_parameters
    end
  end
end
