# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Item source id change" do
  before do
    sign_in create(:user), groups: ["sdr:administrator-role"]
    allow(StateService).to receive(:new).and_return(state_service)
  end

  describe "when modification is not allowed" do
    let(:item) { FactoryBot.create_for_repository(:persisted_item) }
    let(:druid) { item.externalIdentifier }
    let(:state_service) { instance_double(StateService, allows_modification?: false, accessioned?: false) }

    it "cannot change the source id" do
      visit source_id_ui_item_path druid
      fill_in "new_id", with: "sulair:newSource"
      click_button "Update"
      expect(page).to have_css "body", text: "Object cannot be modified in " \
                                             "its current state."
    end
  end

  describe "when modification is allowed" do
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
    let(:druid) { "druid:kv840xx0000" }
    let(:cocina_model) do
      build(:dro_with_metadata, id: druid)
    end
    let(:state_service) { instance_double(StateService, allows_modification?: true, accessioned?: true) }
    let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
        find: cocina_model,
        events: events_client,
        version: version_client,
        update: true)
    end
    let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, milestones: [], workflow_routes:) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)

      # The indexer calls to the workflow service, so stub that out as it's unimportant to this test.
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      solr_conn.add(:id => druid, :objectType_ssim => "item",
        CatalogRecordId.index_field => "#{CatalogRecordId.indexing_prefix}99999")
      solr_conn.commit
    end

    it "changes the source id" do
      visit source_id_ui_item_path druid
      fill_in "new_id", with: "sulair:newSource"
      click_button "Update"
      expect(page).to have_css ".alert.alert-info", text: "Source Id for " \
                                                          "#{druid} has been updated!"
      expect(Argo::Indexer).to have_received(:reindex_druid_remotely)
    end
  end
end
