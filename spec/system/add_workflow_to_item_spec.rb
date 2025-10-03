# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add a workflow to an item' do
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
                    workflow: workflow_client)
  end
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }
  let(:cocina_model) { build(:dro_with_metadata, id: item_id) }
  let(:item_id) { 'druid:bg444xg6666' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true) }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
    solr_conn.add(id: item_id, SolrDocument::FIELD_OBJECT_TYPE => 'item')
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(WorkflowService).to receive(:workflow_active?).with(druid: item_id, version: 1, wf_name: 'gisAssemblyWF').and_return(false)
    allow(WorkflowService).to receive(:workflows_for).with(druid: item_id).and_return([])
    allow(MilestoneService).to receive(:milestones_for).and_return({})
    allow(WorkflowService).to receive(:accessioned?).and_return(true)
  end

  it 'redirect and display on show page' do
    visit new_item_workflow_path item_id
    expect(page).to have_no_css 'option[value="registrationWF"]'
    expect(page).to have_no_css 'option[value="accessionWF"]'
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added gisAssemblyWF'
    end
    expect(object_client).to have_received(:workflow).with('gisAssemblyWF')
    expect(workflow_client).to have_received(:create)
  end
end
