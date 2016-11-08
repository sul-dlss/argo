class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Argo::AccessControlsEnforcement
  include Argo::CustomSearch
  include Argo::DateFieldQueries
  include Argo::ProfileQueries

  self.default_processor_chain += [:add_access_controls_to_solr_params, :pids_only, :add_date_field_queries, :add_profile_queries]
end
