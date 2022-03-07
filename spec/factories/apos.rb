# frozen_string_literal: true

FactoryBot.define do
  factory :apo, class: 'Cocina::Models::RequestAdminPolicy' do
    initialize_with do |*_args|
      ApoMethodSender.new(
        Cocina::Models.build_request({
                                       'type' => type,
                                       'label' => 'test apo',
                                       'version' => 1,
                                       'administrative' => {
                                         'hasAdminPolicy' => admin_policy_id,
                                         'hasAgreement' => agreement_id,
                                         'defaultAccess' => {
                                           'access' => 'world',
                                           'download' => 'world'
                                         }
                                       }
                                     })
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model)
    end

    admin_policy_id { 'druid:hv992ry2431' }

    agreement_id { 'druid:hp308wm0436' }

    type { Cocina::Models::Vocab.admin_policy }
  end
end
