# frozen_string_literal: true

class ReportSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Argo::AccessControlsEnforcement
  include Argo::CustomSearch
  include Argo::DateFieldQueries

  self.default_processor_chain -= [:add_facetting_to_solr] # remove faceting from reports

  self.default_processor_chain += [
    :add_access_controls_to_solr_params, # enforce restrictions
    :add_date_field_queries # ensure date field queries work
  ]
end
