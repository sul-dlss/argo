# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Add a workflow to an item' do
  let(:stub_workflow) { instance_double(Dor::Workflow::Response::Workflow, active_for?: false) }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client,
                    workflow: stub_workflow,
                    create_workflow_by_name: true,
                    all_workflows_xml: '',
                    milestones: [],
                    lifecycle: [],
                    workflow_templates: %w[assemblyWF registrationWF],
                    active_lifecycle: [])
  end

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Config.workflow).to receive(:client).and_return(workflow_client)
  end

  it 'redirect and display on show page' do
    visit new_item_workflow_path 'druid:qq613vj0238'
    click_button 'Add'
    within '.flash_messages' do
      # The selected workflow defaults to Settings.apo.default_workflow_option (registrationWF)
      expect(page).to have_css '.alert.alert-info', text: 'Added registrationWF'
    end
    expect(workflow_client).to have_received(:create_workflow_by_name)
  end
end
