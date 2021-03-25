# frozen_string_literal: true

FactoryBot.define do
  factory :ur_apo, class: 'Dor::AdminPolicyObject' do
    initialize_with do
      Dor::AdminPolicyObject.new(pid: 'druid:hv992ry2431', label: 'Ur-APO',
                                 # admin_policy_object_id: 'druid:hv992ry2431', doesn't work.
                                 agreement_object_id: 'druid:hv992ry2431',
                                 mods_title: 'Ur-APO').tap do |ur_apo|
        ur_apo.add_relationship(:is_governed_by, 'info:fedora/druid:hv992ry2431')
      end
    end
    to_create do |ur_apo|
      ur_apo.save!

      # Solves an odd bootstrapping problem, where the dor-indexing-app can only index cocina-models,
      # but cocina-model can't be built unless the AdminPolicy is found in Solr
      conn = ActiveFedora::SolrService.instance.conn
      conn.add(id: 'druid:hv992ry2431',
               objectType_ssim: ['adminPolicy'],
               has_model_ssim: ['info:fedora/afmodel:Dor_AdminPolicyObject'])
      conn.commit
      ur_apo
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

    admin_policy_id { FactoryBot.create_for_repository(:ur_apo).pid }

    type { Cocina::Models::Vocab.admin_policy }
  end
end
