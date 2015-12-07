class SearchBuilder < Blacklight::Solr::SearchBuilder
  include Argo::AccessControlsEnforcement
  include Argo::CustomSearch

  self.default_processor_chain += [:add_access_controls_to_solr_params, :pids_only]

  def initialize(processor_chain, scope)
    super(processor_chain, scope)
    @processor_chain += [:add_access_controls_to_solr_params] unless @processor_chain.include?(:add_access_controls_to_solr_params)
    @processor_chain += [:pids_only] unless @processor_chain.include?(:pids_only)
  end
end
