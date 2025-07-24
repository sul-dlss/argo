# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item source id change' do
  before do
    allow(WorkflowService).to receive_messages(accessioned?: false, workflows_for: [])
    allow(MilestoneService).to receive(:milestones_for).and_return({})
    allow(VersionService).to receive(:new).and_return(version_service)

    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  describe 'when modification is not allowed' do
    let(:item) { FactoryBot.create_for_repository(:persisted_item) }
    let(:druid) { item.externalIdentifier }
    let(:version_service) { instance_double(VersionService, open_and_not_assembling?: false, closed?: true, open?: false) }

    it 'cannot change the source id' do
      visit source_id_ui_item_path druid
      fill_in 'new_id', with: 'sulair:newSource'
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
                                             'its current state.'
    end
  end

  describe 'when modification is allowed' do
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
    let(:druid) { 'druid:kv840xx0000' }
    let(:cocina_model) do
      build(:dro_with_metadata, id: druid)
    end
    let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true, closed?: false, open?: true) }
    let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
    let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina_model,
                      find_lite: cocina_model, # NOTE: This should really be a DROLite
                      events: events_client,
                      version: version_client,
                      user_version: user_version_client,
                      release_tags: release_tags_client,
                      update: true,
                      reindex: true)
    end
    let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, milestones: [], workflow_routes:) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(WorkflowService).to receive(:accessioned?).and_return(true)

      # The indexer calls to the workflow service, so stub that out as it's unimportant to this test.
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      solr_conn.add(:id => druid, :objectType_ssim => 'item',
                    CatalogRecordId.index_field => "#{CatalogRecordId.indexing_prefix}99999")
      solr_conn.commit
    end

    it 'changes the source id' do
      visit source_id_ui_item_path druid
      fill_in 'new_id', with: 'sulair:newSource'
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: 'Source Id for ' \
                                                          "#{druid} has been updated!"
      expect(object_client).to have_received(:reindex)
    end
  end
end
