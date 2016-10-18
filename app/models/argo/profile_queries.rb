module Argo
  ##
  # Part of the Blacklight SearchBuilder, but only used for ProfileController to
  # add additional parameters to the Solr request.
  module ProfileQueries
    extend ActiveSupport::Concern

    def add_profile_queries(solr_parameters)
      return solr_parameters unless blacklight_params['controller'] == 'profile'
      solr_parameters['facet.field'] ||= []
      solr_parameters['facet.field'] << SolrDocument::FIELD_APO_TITLE.to_s
      solr_parameters['facet.field'] << SolrDocument::SolrDocument::FIELD_COLLECTION_TITLE.to_s
      solr_parameters['facet.field'] << 'use_statement_ssim'
      solr_parameters['facet.field'] << 'copyright_ssim'
      solr_parameters['stats'] = true
      solr_parameters['stats.field'] ||= []
      # Use this paradigm to compute needed statistics
      # solr_parameters['stats.field'] << 'published_dttsim'
      solr_parameters
    end
  end
end
