# frozen_string_literal: true

FactoryBot.define do
  factory :apo, class: Cocina::Models::RequestAdminPolicy do
    initialize_with do
      Cocina::Models.build_request(
        'type' => type,
        'label' => 'test apo',
        'version' => 1,
        'administrative' => {
          'hasAdminPolicy' => apo.pid
        }
      )
    end

    to_create do |cocina_model|
      Dor::Services::Client.objects.register(params: cocina_model)
    end

    apo do
      Dor::AdminPolicyObject.create(pid: 'druid:hv992ry2431')
    end

    type { Cocina::Models::Vocab.admin_policy }
  end
end
