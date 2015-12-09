class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Argo::AccessControlsEnforcement

  self.default_processor_chain += [:add_access_controls_to_solr_params]

  def initialize(processor_chain, scope)
    super(processor_chain, scope)
    @processor_chain += [:add_access_controls_to_solr_params] unless @processor_chain.include?(:add_access_controls_to_solr_params)
  end
end
