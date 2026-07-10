# frozen_string_literal: true

FactoryBot.define do
  factory :persisted_apo, class: 'Cocina::Models::RequestAdminPolicy' do
    initialize_with do |*_args|
      ApoMethodSender.new(
        Cocina::Models.build_request({
                                       'type' => type,
                                       'version' => 1,
                                       'administrative' => {
                                         'hasAdminPolicy' => admin_policy_id,
                                         'hasAgreement' => agreement_id,
                                         'accessTemplate' => {
                                           'view' => 'world',
                                           'download' => 'world'
                                         }
                                       },
                                       'description' => {
                                         'title' => [{ value: title }]
                                       }
                                     })
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id { 'druid:hv992ry2431' }
    agreement_id { FactoryBot.create_for_repository(:agreement).externalIdentifier }
    title { 'this is a really long test APO title to test truncation of facet labels on show page' }
    type { Cocina::Models::ObjectType.admin_policy }
  end
end
