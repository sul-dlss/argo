# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item catkey change' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor).to receive(:find).with(druid).and_return(obj)
    allow(obj).to receive(:new_record?).and_return(false)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:druid) { 'druid:kv840xx0000' }
  let(:obj) { Dor::Item.new(pid: druid, catkey: '99999') }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) { instance_double(Cocina::Models::DRO) }

  describe 'when modification is not allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: false) }

    it 'cannot change the catkey' do
      visit catkey_ui_item_path druid
      fill_in 'new_catkey', with: '12345'
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
        'its current state.'
    end
  end

  describe 'when modification is allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: true) }
    let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, events: events_client, update: true) }
    let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }
    let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, milestones: [], workflow_routes: workflow_routes) }
    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => druid,
                             'access' => {
                               'access' => 'world'
                             },
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end

    before do
      # The indexer calls to the workflow service, so stub that out as it's unimportant to this test.
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      ActiveFedora::SolrService.add(id: druid, objectType_ssim: 'item',
                                    SolrDocument::FIELD_CATKEY_ID => 'catkey:99999')
      ActiveFedora::SolrService.commit
    end

    it 'changes the catkey' do
      visit catkey_ui_item_path druid
      fill_in 'new_catkey', with: '12345'
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: 'Catkey for ' \
        "#{druid} has been updated!"
      expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      expect(state_service).to have_received(:allows_modification?).exactly(3).times
    end
  end
end
