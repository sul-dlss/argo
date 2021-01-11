# frozen_string_literal: true

FactoryBot.define do
  factory :item, class: 'Cocina::Models::RequestDRO' do
    initialize_with do
      Cocina::Models.build_request({
                                     'type' => type,
                                     'label' => 'test object',
                                     'version' => 1,
                                     'identification' => {
                                       'sourceId' => "sul:#{SecureRandom.uuid}"
                                     },
                                     'administrative' => {
                                       'hasAdminPolicy' => apo.pid
                                     }
                                   })
    end

    to_create do |cocina_model|
      Dor::Services::Client.objects.register(params: cocina_model)
    end

    apo { Dor::AdminPolicyObject.create(pid: 'druid:hv992ry2431') }
    type { Cocina::Models::Vocab.object }
  end
end
