# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Workflow Service Creation' do
  let(:stub_workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Config.workflow.client).to receive(:workflow).and_return(stub_workflow)
    allow(Dor::Config.workflow.client).to receive(:create_workflow).and_return(true)
    allow(Dor::Config.workflow.client).to receive(:milestones).and_return([])
    allow(Dor::Config.workflow.client).to receive(:lifecycle).and_return([])
    allow(Dor::Config.workflow.client).to receive(:active_lifecycle).and_return([])
    # TODO: When we have dor-services 6.7.0 we can do this to simulate the change create_workflow would have made on the indexed doc
    # allow_any_instance_of(Dor::WorkflowSolrDocument).to receive(:to_h).and_return('workflow_status_ssim' => ['accessionWF'])
  end

  it 'redirect and display on show page' do
    visit new_item_workflow_path 'druid:qq613vj0238'
    click_button 'Add'
    within '.flash_messages' do
      expect(page).to have_css '.alert.alert-info', text: 'Added accessionWF'
    end
    expect(Dor::Config.workflow.client).to have_received(:create_workflow)
    # The workflow would create a workflow and index it into workflow_status_ssim
    # expect(page).to have_css 'tr td a', text: 'accessionWF'
  end
end
