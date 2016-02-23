class SearchBuilder < Blacklight::Solr::SearchBuilder
  include Argo::AccessControlsEnforcement
  include Argo::CustomSearch
  include Argo::DateFieldQueries

  self.default_processor_chain += [:add_access_controls_to_solr_params, :pids_only, :add_date_field_queries]

  def initialize(processor_chain, scope)
    super(processor_chain, scope)
    @processor_chain += [:add_access_controls_to_solr_params] unless @processor_chain.include?(:add_access_controls_to_solr_params)
    @processor_chain += [:pids_only] unless @processor_chain.include?(:pids_only)
    @processor_chain += [:add_date_field_queries] unless @processor_chain.include?(:add_date_field_queries)
  end
end
