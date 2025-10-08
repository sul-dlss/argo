# frozen_string_literal: true

module Argo
  module AccessControlsEnforcement
    extend ActiveSupport::Concern

    def add_access_controls_to_solr_params(solr_parameters)
      apply_gated_discovery(solr_parameters, scope.context.fetch(:current_user))
    end

    private

    def apply_gated_discovery(solr_parameters, user)
      # Repository wide admin, manager and viewer users access everything
      return solr_parameters if user.admin? || user.manager? || user.viewer?

      druids = user.permitted_apos
      # Do this as a negative query, exclude items they cannot access
      # rather than including items they can access.
      solr_druids = druids.map { |p| "\"#{p}\"" }.join(' OR ')
      # Check for an empty set of DRUIDs.  If empty, they aren't supposed to see
      # anything, but use a dummy value to make sure the solr query is valid.
      solr_druids = 'dummy_value' if solr_druids.blank?
      # Initialize and/or append to :fq
      solr_parameters[:fq] ||= []
      solr_parameters[:fq] << "#{SolrDocument::FIELD_APO_ID}:(#{solr_druids})"
      solr_parameters
    end
  end
end
