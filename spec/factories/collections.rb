# frozen_string_literal: true

FactoryBot.define do
  factory :persisted_collection, class: 'Cocina::Models::RequestCollection' do
    initialize_with do |*_args|
      CollectionMethodSender.new(
        Cocina::Models.build_request({
                                       'type' => type,
                                       'label' => 'test collection',
                                       'version' => 1,
                                       'administrative' => {
                                         'hasAdminPolicy' => admin_policy_id
                                       },
                                       :identification => { sourceId: "sul:#{SecureRandom.uuid}" },
                                       'access' => {}
                                     })
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id { 'druid:hv992ry2431' }

    type { Cocina::Models::ObjectType.collection }
  end
end
