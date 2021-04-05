# frozen_string_literal: true

module ResetSolr
  def reset_solr
    blacklight_config = CatalogController.blacklight_config
    solr_conn = blacklight_config.repository_class.new(blacklight_config).connection
    solr_conn.delete_by_query('*:*')

    # Solves an odd bootstrapping problem, where the dor-indexing-app can only index cocina-models,
    # but cocina-model can't be built unless the AdminPolicy is found in Solr
    solr_conn.add(id: 'druid:hv992ry2431',
                  objectType_ssim: ['adminPolicy'],
                  apo_register_permissions_ssim: ['workgroup:dlss:developers'],
                  sw_display_title_tesim: ['[Internal System Objects]'],
                  has_model_ssim: ['info:fedora/afmodel:Dor_AdminPolicyObject'])
    solr_conn.commit
  end
end

RSpec.configure do |config|
  config.include ResetSolr
  config.before(:suite) { Class.new { include ResetSolr }.new.reset_solr }
end
