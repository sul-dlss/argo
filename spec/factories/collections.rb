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
                                       identification: { sourceId: 'sul:1234' },
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

  factory :collection do
    initialize_with do
      new(
        Cocina::Models.build({
                               externalIdentifier: id,
                               type: type,
                               label: label,
                               version: 1,
                               description: {
                                 title: [{ value: title }],
                                 purl: purl
                               },
                               identification: {},
                               administrative: {
                                 hasAdminPolicy: admin_policy_id
                               },
                               access: {}
                             })
      )
    end

    id { 'druid:bc234fg5678' }
    version { 1 }
    admin_policy_id { 'druid:hv992ry2431' }
    label { 'test object' }
    type { Cocina::Models::ObjectType.collection }
    title { 'my dro' }
    purl { 'https://purl.stanford.edu/bc234fg5678' }
  end
end
