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
                    workflow_routes: workflow_routes,
                    milestones: [],
                    lifecycle: [],
                    workflow_templates: %w[assemblyWF registrationWF],
                    active_lifecycle: [])
  end
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:metadata_client) { instance_double(Dor::Services::Client::Metadata, datastreams: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find: cocina_model,
                    events: events_client,
                    metadata: metadata_client,
                    version: version_client)
  end
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The model',
                           'version' => 2,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => item_id,
                           'description' => {
                             'title' => [{ 'value' => 'The model' }],
                             'purl' => "https://purl.stanford.edu/#{item_id.delete_prefix('druid:')}"
                           },
                           'administrative' => { hasAdminPolicy: uber_apo_id },
                           'access' => {},
                           'structural' => {},
                           'identification' => {}
                         })
  end
  let(:uber_apo_id) { 'druid:hv992ry2431' }
  let(:item_id) { 'druid:bg444xg6666' }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    solr_conn.add(id: item_id, objectType_ssim: 'item')
    solr_conn.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(workflow_client).to receive(:workflow_status).with(druid: 'druid:bg444xg6666', process: 'accessioning-initiate', workflow: 'assemblyWF').and_return(true)
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  it 'redirect and display on show page' do
    visit new_item_workflow_path item_id
    click_button 'Add'
    within '.flash_messages' do
      # The selected workflow defaults to Settings.apo.default_workflow_option (registrationWF)
      expect(page).to have_css '.alert.alert-info', text: 'Added registrationWF'
    end
    expect(workflow_client).to have_received(:create_workflow_by_name)
  end
end
