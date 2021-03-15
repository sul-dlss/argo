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
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, events: events_client) }
  let(:cocina_model) do
    instance_double(Cocina::Models::DRO,
                    externalIdentifier: item_id,
                    version: 2,
                    administrative: administrative,
                    structural: structural,
                    as_json: {})
  end
  let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: []) }
  let(:uber_apo_id) { 'druid:hv992ry2431' }
  let(:item_id) { 'druid:bg444xg6666' }

  before do
    # this bit required while the CatalogController still loads from Fedora:
    item = Dor::Item.new(pid: 'druid:bg444xg6666', label: 'Foo', source_id: 'sauce:99', admin_policy_object_id: uber_apo_id)
    item.descMetadata.mods_title = 'Test'
    item.save!
    ActiveFedora::SolrService.add(id: item_id, objectType_ssim: 'item')
    ActiveFedora::SolrService.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
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
