# frozen_string_literal: true

FactoryBot.define do
  factory :ur_apo, class: 'Cocina::Models::RequestAdminPolicy' do
    initialize_with do
      nil
    end
    to_create do
      # Solves an odd bootstrapping problem, where the dor-indexing-app can only index cocina-models,
      # but cocina-model can't be built unless the AdminPolicy is found in Solr
      blacklight_config = CatalogController.blacklight_config
      conn = blacklight_config.repository_class.new(blacklight_config).connection
      conn.add(id: 'druid:hv992ry2431',
               objectType_ssim: ['adminPolicy'],
               has_model_ssim: ['info:fedora/afmodel:Dor_AdminPolicyObject'])
      conn.commit
      SolrDocument.new(id: 'druid:hv992ry2431')
    end
  end

  factory :apo, class: 'Cocina::Models::RequestAdminPolicy' do
    initialize_with do |*_args|
      ApoMethodSender.new(
        Cocina::Models.build_request(
          'type' => type,
          'label' => 'test apo',
          'version' => 1,
          'administrative' => {
            'hasAdminPolicy' => admin_policy_id
          }
        )
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id { FactoryBot.create_for_repository(:ur_apo).id }

    type { Cocina::Models::Vocab.admin_policy }
  end
end
