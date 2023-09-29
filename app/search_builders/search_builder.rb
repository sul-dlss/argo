# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Argo::AccessControlsEnforcement
  include Argo::CustomSearch
  include Argo::DateFieldQueries
  include Argo::ProfileQueries

  self.default_processor_chain += %i[
    add_access_controls_to_solr_params
    druids_only
    add_date_field_queries
    add_profile_queries
  ]

  # Override blacklight in order to customize facet paging behavior.
  # This allows a separately configurable limit for the full list of facets
  def add_facet_paging_to_solr(solr_params)
    return if facet.blank?

    super

    facet_config = blacklight_config.facet_fields[facet]

    return unless facet_config.more_limit

    limit = if scope.respond_to?(:facet_list_limit)
              scope.facet_list_limit.to_s.to_i
            elsif solr_params['facet.limit']
              solr_params['facet.limit'].to_i
            else
              facet_config[:more_limit]
            end

    page = blacklight_params.fetch(request[:page], 1).to_i
    offset = (page - 1) * limit

    solr_params[:"f.#{facet}.facet.limit"] = limit + 1
    solr_params[:"f.#{facet}.facet.offset"] = offset
  end
end
