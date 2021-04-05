# frozen_string_literal: true

FactoryBot.define do
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

    admin_policy_id { 'druid:hv992ry2431' }

    type { Cocina::Models::Vocab.admin_policy }
  end
end
