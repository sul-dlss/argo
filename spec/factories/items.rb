# frozen_string_literal: true

FactoryBot.define do
  factory :item, class: 'Cocina::Models::RequestDRO' do
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
                                       'access' => {}
                                     })
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id { 'druid:hv992ry2431' }
    label { 'test object' }
    type { Cocina::Models::Vocab.object }

    factory :agreement do
      type { Cocina::Models::Vocab.agreement }
    end
  end
end
