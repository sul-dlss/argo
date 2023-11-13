# frozen_string_literal: true

module BlacklightConfigHelper
  def self.add_common_default_solr_params_to_config!(config)
    config.default_solr_params = {
      'q.alt': '*:*',
      defType: 'dismax',
      qf: %(
        sw_display_title_tesim^5
        contributor_text_nostem_im^3
        topic_tesim^2

        tag_ssim

        originInfo_place_placeTerm_tesim
        originInfo_publisher_tesim

        content_type_ssim
        sw_format_ssim
        object_type_ssim

        descriptive_text_nostem_i
        descriptive_tiv
        descriptive_teiv

        collection_title_tesim

        id
        objectId_tesim
        obj_label_tesim
        identifier_ssim
        identifier_tesim
        barcode_id_ssim
        folio_instance_hrid_ssim
        source_id_text_nostem_i^3
        source_id_ssi
        previous_ils_ids_ssim
        doi_ssim
        contributor_orcids_ssim
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
