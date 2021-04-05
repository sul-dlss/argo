# frozen_string_literal: true

FactoryBot.define do
  factory :collection, class: 'Cocina::Models::RequestCollection' do
    initialize_with do |*_args|
      CollectionMethodSender.new(
        Cocina::Models.build_request(
          'type' => type,
          'label' => 'test collection',
          'version' => 1,
          'administrative' => {
            'hasAdminPolicy' => admin_policy_id
          },
          'access' => {}
        )
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id { FactoryBot.create_for_repository(:ur_apo).pid }

    type { Cocina::Models::Vocab.collection }
  end
end
