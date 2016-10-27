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
      solr_parameters['stats.field'] << 'sw_pub_date_facet_ssi'
      solr_parameters['stats.field'] << 'content_file_count_itsi'
      solr_parameters['stats.field'] << 'shelved_content_file_count_itsi'
      solr_parameters['stats.field'] << 'preserved_size_dbtsi'
      solr_parameters['stats.field'] << 'catkey_id_ssim'
      # Use this paradigm to add pivot facets
      solr_parameters['facet.pivot'] ||= []
      solr_parameters['facet.pivot'] << "#{SolrDocument::FIELD_OBJECT_TYPE},processing_status_text_ssi"
      # Use this paradigm to add facet queries
      solr_parameters['facet.query'] ||= []
      solr_parameters['facet.query'] << '-rights_primary_ssi:"dark" AND published_dttsim:*'
      solr_parameters
    end
  end
end
