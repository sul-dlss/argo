# frozen_string_literal: true

FactoryBot.define do
  factory :persisted_apo, class: "Cocina::Models::RequestAdminPolicy" do
    initialize_with do |*_args|
      ApoMethodSender.new(
        Cocina::Models.build_request({
          "type" => type,
          "label" => "test apo",
          "version" => 1,
          "administrative" => {
            "hasAdminPolicy" => admin_policy_id,
            "hasAgreement" => agreement_id,
            "accessTemplate" => {
              "view" => "world",
              "download" => "world"
            }
          }
        })
      )
    end

    to_create do |builder|
      Dor::Services::Client.objects.register(params: builder.cocina_model).tap do |apo|
        # Since we don't run the rabbitMQ service in our cluster, we have to index these manually
        Argo::Indexer.reindex_druid_remotely(apo.externalIdentifier)
      end
    end

    admin_policy_id { "druid:hv992ry2431" }

    agreement_id { "druid:hp308wm0436" }

    type { Cocina::Models::ObjectType.admin_policy }
  end
end
