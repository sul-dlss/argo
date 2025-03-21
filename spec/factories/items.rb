# frozen_string_literal: true

# Because we are instantiating an immutable cocina-model rather than a database record,
#   nested hash structure values (e.g. a title value in a description)
#   may require a setter method in ItemMethodSender before they can be passed in
FactoryBot.define do
  factory :persisted_item, class: 'Cocina::Models::RequestDRO' do
    initialize_with do
      ItemMethodSender.new(
        Cocina::Models.build_request({
                                       'type' => type,
                                       'label' => label,
                                       'version' => 1,
                                       'identification' => identification,
                                       'administrative' => {
                                         'hasAdminPolicy' => admin_policy_id
                                       },
                                       'access' => {},
                                       'structural' => {}
                                     })
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id do
      FactoryBot.create_for_repository(:persisted_apo,
                                       roles: [{ name: 'dor-apo-manager',
                                                 members: [{ identifier: 'sdr:administrator-role',
                                                             type: 'workgroup' }] }]).externalIdentifier
    end
    label { 'test object' }
    type { Cocina::Models::ObjectType.object }
    source_id { "sul:#{SecureRandom.uuid}" }
    identification do
      {
        'sourceId' => source_id
      }
    end

    factory :agreement do
      type { Cocina::Models::ObjectType.agreement }
      label { 'Test Agreement' }
      admin_policy_id { 'druid:hv992ry2431' }
    end
  end
end
