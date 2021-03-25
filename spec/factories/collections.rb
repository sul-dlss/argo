# frozen_string_literal: true

FactoryBot.define do
  factory :collection, class: 'Cocina::Models::RequestDRO' do
    initialize_with do
      Cocina::Models.build_request({
                                     'type' => type,
                                     'label' => 'test object',
                                     'version' => 1,
                                     'access' => {
                                     },
                                     'administrative' => {
                                       'hasAdminPolicy' => apo.pid
                                     }
                                   })
    end

    to_create do |cocina_model|
      Dor::Services::Client.objects.register(params: cocina_model)
    end

    apo do
      FactoryBot.create_for_repository(:ur_apo)
    end

    type { Cocina::Models::Vocab.collection }
  end
end
