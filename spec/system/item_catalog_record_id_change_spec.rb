# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item catalog_record_id change' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(WorkflowService).to receive_messages(accessioned?: false, workflows_for: [])
    allow(MilestoneService).to receive(:milestones_for).and_return({})
  end

  describe 'when modification is not allowed' do
    let(:item) { FactoryBot.create_for_repository(:persisted_item) }
    let(:druid) { item.externalIdentifier }
    let(:version_service) { instance_double(VersionService, open_and_not_assembling?: false, open?: false) }

    it 'cannot change the catalog_record_id' do
      visit edit_item_catalog_record_id_path druid
      within '.modal-body' do
        find('input').set '12345'
      end
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
                                             'its current state.'
    end
  end

  describe 'when modification is allowed' do
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
    let(:druid) { 'druid:kv840xx0000' }
    let(:cocina_model) { build(:dro_with_metadata, id: druid) }
    let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true, open?: true) }
    let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
    let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina_model,
                      find_lite: cocina_model, # NOTE: This should really be a DROLite
                      events: events_client,
                      update: true,
                      version: version_client,
                      user_version: user_version_client,
                      release_tags: release_tags_client,
                      reindex: true)
    end
    let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(WorkflowService).to receive(:accessioned?).and_return(true)

      # The indexer calls to the workflow service, so stub that out as it's unimportant to this test.
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      solr_conn.add(:id => druid, SolrDocument::FIELD_OBJECT_TYPE => 'item',
                    CatalogRecordId.index_field => "#{CatalogRecordId.indexing_prefix}99999")
      solr_conn.commit
    end

    it 'changes the catalog_record_id' do
      visit edit_item_catalog_record_id_path druid
      within '.modal-body' do
        find('input').set 'a12345'
        find('select').set true
      end
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: "#{CatalogRecordId.label}s for " \
                                                          "#{druid} have been updated!"
      expect(object_client).to have_received(:reindex)
    end
  end
end
