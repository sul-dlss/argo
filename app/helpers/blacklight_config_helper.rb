# frozen_string_literal: true

module BlacklightConfigHelper
  def self.add_common_default_solr_params_to_config!(config)
    config.default_solr_params = {
      'q.alt': '*:*',
      defType: 'dismax',
      qf: %(
        collection_title_tesim
        dor_id_tesim
        identifier_tesim
        obj_label_tesim
        objectId_tesim
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
