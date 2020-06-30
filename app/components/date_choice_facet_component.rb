# frozen_string_literal: true

class DateChoiceFacetComponent < Blacklight::FacetFieldListComponent
  def search_params
    @facet_field.search_state.params_for_search.except(:page, :utf8)
  end

  def solr_field_name
    @facet_field.facet_field.raw_facet_field
  end
end
