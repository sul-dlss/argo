# frozen_string_literal: true

# Used in CatalogController.  This module is split out because catalog_controller.rb
#  contains all the required blacklight configurations and is plenty large enough.
#
# See spec/system/indexing_xxx_spec.rb for relevancy tests of Solr search results
module BlacklightConfigHelper
  # sending these values to Solr as arguments with search requests will override
  #   the default params configured for Solr searching via solrconfig.xml
  def self.add_common_default_solr_params_to_config!(config)
    config.default_solr_params = {
      'q.alt': '*:*',
      defType: 'dismax',
      qf: %(
        main_title_text_anchored_im^100
        main_title_text_unstemmed_im^50
        main_title_tenim^10
        full_title_unstemmed_im^10
        full_title_tenim^5
        additional_titles_unstemmed_im^5
        additional_titles_tenim^3

        author_text_nostem_im^3
        contributor_text_nostem_im

        topic_tesim^2

        tag_text_unstemmed_im

        originInfo_place_placeTerm_tesim
        originInfo_publisher_tesim

        content_type_ssimdv
        sw_format_ssim
        object_type_ssim

        descriptive_text_nostem_i
        descriptive_tiv
        descriptive_teiv

        collection_title_tesim

        id
        druid_bare_ssi
        druid_prefixed_ssi
        obj_label_tesim
        identifier_ssim
        identifier_tesim
        barcode_id_ssimdv
        folio_instance_hrid_ssim
        source_id_text_nostem_i^3
        source_id_ssi
        previous_ils_ids_ssim
        doi_ssimdv
        contributor_orcids_ssimdv
      ),
      facet: true,
      'facet.mincount': 1,
      'f.wf_wps_ssim.facet.limit': -1,
      'f.wf_wsp_ssim.facet.limit': -1,
      'f.wf_swp_ssim.facet.limit': -1,
      'f.exploded_project_tag_ssim.facet.limit': -1,
      'f.exploded_project_tag_ssim.facet.sort': 'index',
      'f.exploded_nonproject_tag_ssim.facet.limit': -1,
      'f.exploded_nonproject_tag_ssim.facet.sort': 'index'
    }
  end
end
