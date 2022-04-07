# frozen_string_literal: true

FactoryBot.define do
  factory :persisted_item, class: 'Cocina::Models::RequestDRO' do
    initialize_with do
      ItemMethodSender.new(
        Cocina::Models.build_request({
                                       'type' => type,
                                       'label' => label,
                                       'version' => 1,
                                       'identification' => {
                                         'sourceId' => "sul:#{SecureRandom.uuid}"
                                       },
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

    admin_policy_id { 'druid:hv992ry2431' }
    label { 'test object' }
    type { Cocina::Models::ObjectType.object }

    factory :agreement do
      type { Cocina::Models::ObjectType.agreement }
    end
  end
end
