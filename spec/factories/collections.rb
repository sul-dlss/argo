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
                                       'identification' => {},
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

  factory :collection, class: 'Cocina::Models::Collection' do
    initialize_with do |*_args|
      CollectionMethodSender.new(
        Cocina::Models.build({
                               externalIdentifier: external_identifier,
                               type: type,
                               label: 'test collection',
                               version: 1,
                               description: {
                                 title: [{ value: title }],
                                 purl: purl
                               },
                               administrative: {
                                 hasAdminPolicy: admin_policy_id
                               },
                               identification: {},
                               access: {}
                             })
      )
    end

    admin_policy_id { 'druid:hv992ry2431' }
    external_identifier { 'druid:bc123df4568' }

    label { 'test object' }
    type { Cocina::Models::ObjectType.collection }
    title { 'my collection' }
    purl { 'https://purl.stanford.edu/bc123df4568' }
  end
end
