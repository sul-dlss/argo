module BlacklightConfigHelper
  def self.add_common_default_solr_params_to_config!(config)
    config.default_solr_params = {
      'q.alt': '*:*',
      defType: 'dismax',
      qf: %(
        text^3
        collection_title_tesim
        creator_tesim
        dc_creator_tesim
        dc_identifier_druid_tesim
        dc_title_tesim
        dor_id_tesim
        extent_ssim
        identifier_tesim
        lifecycle_ssim
        obj_label_tesim
        obj_state_tesim
        originInfo_place_placeTerm_tesim
        originInfo_publisher_tesim
        sw_display_title_tesim
        scale_ssim
        source_id_ssim
        tag_ssim
        title_tesim
        topic_tesim
      ),
      facet: true,
      'facet.mincount': 1,
      'f.wf_wps_ssim.facet.limit': -1,
      'f.wf_wsp_ssim.facet.limit': -1,
      'f.wf_swp_ssim.facet.limit': -1,
      'f.tag_ssim.facet.limit': -1,
      'f.tag_ssim.facet.sort': 'index'
    }
  end
end
