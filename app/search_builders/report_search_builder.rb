# frozen_string_literal: true

class ReportSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Argo::AccessControlsEnforcement

  self.default_processor_chain -= [:add_facetting_to_solr]
end
