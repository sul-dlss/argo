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
      Dor::Services::Client.objects.register(params: builder.cocina_model).tap do |collection|
        # Since we don't run the rabbitMQ service in our cluster, we have to index these manually
        Argo::Indexer.reindex_druid_remotely(collection.externalIdentifier)
      end
    end

    admin_policy_id { 'druid:hv992ry2431' }

    type { Cocina::Models::ObjectType.collection }
  end
end
