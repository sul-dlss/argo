# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item catkey change' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(StateService).to receive(:new).and_return(state_service)
  end

  describe 'when modification is not allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: false) }

    it 'cannot change the catkey' do
      visit catkey_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_catkey', with: '12345'
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Object cannot be modified in ' \
        'its current state.'
    end
  end

  describe 'when modification is allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: true) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative) }
    let(:administrative) { instance_double(Cocina::Models::DRO::Administrative, releaseTags: []) }
    let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
    let(:workflow_client) { instance_double(Dor::Workflow::Client, milestones: [], workflow_routes: workflow_routes) }

    before do
      # The indexer calls to the workflow service, so stub that out as it's unimportant to this test.
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    it 'changes the catkey' do
      visit catkey_ui_item_path 'druid:kv840rx2720'
      fill_in 'new_catkey', with: '12345'
      click_button 'Update'
      expect(page).to have_css '.alert.alert-info', text: 'Catkey for ' \
        'druid:kv840rx2720 has been updated!'
      expect(state_service).to have_received(:allows_modification?).exactly(3).times
    end
  end
end
