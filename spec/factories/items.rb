# frozen_string_literal: true

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
      Dor::Services::Client.objects.register(params: builder.cocina_model).tap do |item|
        # Since we don't run the rabbitMQ service in our cluster, we have to index these manually
        Argo::Indexer.reindex_druid_remotely(item.externalIdentifier)
      end
    end

    admin_policy_id { 'druid:hv992ry2431' }
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
    end
  end
end
