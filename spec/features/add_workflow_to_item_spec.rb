# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add a workflow to an item' do
  let(:stub_workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
  let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
  let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client,
                    workflow: stub_workflow,
                    create_workflow_by_name: true,
                    workflow_routes:,
                    milestones: [],
                    lifecycle: [],
                    workflow_templates: %w[assemblyWF registrationWF],
                    active_lifecycle: [])
  end
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
                    reindex: true)
  end
  let(:cocina_model) { build(:dro_with_metadata, id: item_id) }
  let(:item_id) { 'druid:bg444xg6666' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:version_service) { instance_double(VersionService, open_and_not_processing?: true) }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
    solr_conn.add(id: item_id, objectType_ssim: 'item')
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(workflow_client).to receive(:workflow_status).with(druid: 'druid:bg444xg6666',
                                                             process: 'accessioning-initiate', workflow: 'assemblyWF').and_return(true)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  it 'redirect and display on show page' do
    visit new_item_workflow_path item_id
    expect(page).to have_no_css 'option[value="registrationWF"]'
    expect(page).to have_no_css 'option[value="accessionWF"]'
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added gisAssemblyWF'
    end
    expect(workflow_client).to have_received(:create_workflow_by_name)
  end
end
