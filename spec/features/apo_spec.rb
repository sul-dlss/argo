# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create an apo', js: true do
  let(:user) { create(:user) }
  let(:workflows_response) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
  let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: workflows_response) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client) }
  # An Agreement object must exist to populate the dropdown on the form
  let(:agreement) { FactoryBot.create_for_repository(:agreement) }
  let!(:preexisting_collection) do
    FactoryBot.create_for_repository(:collection,
                                     label: 'Another type of collection',
                                     title: 'Another type of collection',
                                     admin_policy_id: agreement.administrative.hasAdminPolicy)
  end

  before do
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)

    allow(workflow_client).to receive_messages(workflow_templates: ['accessionWF'],
                                               create_workflow_by_name: true,
                                               lifecycle: [],
                                               active_lifecycle: [],
                                               milestones: [],
                                               workflow_routes: workflow_routes,
                                               workflow_status: nil)

    sign_in user, groups: ['sdr:administrator-role']
  end

  it 'creates and edits an apo' do
    # go to the registration form and fill it in
    visit new_apo_path
    fill_in 'Title', with: 'APO Title'
    fill_in 'Default Copyright statement', with: 'Copyright statement'
    fill_in 'Default Use and Reproduction statement', with: 'Use statement'

    fill_in 'Group name', with: 'developers'
    click_button 'Add'

    fill_in 'Group name', with: 'someone'
    select 'View', from: 'permissionRole'
    click_button 'Add'

    page.select('Attribution Share Alike 3.0 Unported', from: 'Default use license')

    page.select('accessionWF', from: 'apo_form_default_workflows')

    choose 'Create a Collection'
    fill_in 'Collection Title', with: 'New Testing Collection'

    click_button 'Register APO'
    expect(page).to have_text 'created'

    click_on 'Edit APO'
    expect(find_field('Title').value).to eq('APO Title')
    expect(find_field('Default Copyright statement').value).to eq('Copyright statement')
    expect(find_field('Default Use and Reproduction statement').value).to eq('Use statement')
    expect(page).to have_selector('.permissionName', text: 'developers')
    expect(page).to have_selector('.permissionName', text: 'someone')
    expect(find_field('Default use license').value).to eq 'https://creativecommons.org/licenses/by-sa/3.0/legalcode'
    within_fieldset 'Default Collections' do
      expect(page).to have_link('New Testing Collection')
    end

    # Now change them
    fill_in 'Group name', with: 'dpg-staff'
    click_button 'Add'

    fill_in 'Group name', with: 'anyone'
    select 'View', from: 'permissionRole'
    click_button 'Add'

    fill_in 'Title', with: 'New APO Title'
    fill_in 'Default Copyright statement', with: 'New copyright statement'
    fill_in 'Default Use and Reproduction statement', with: 'New use statement'
    select 'Attribution No Derivatives 3.0 Unported', from: 'Default use license'
    click_button 'Update APO'

    click_on 'Edit APO'
    expect(find_field('Title').value).to eq('New APO Title')
    expect(find_field('Default Copyright statement').value).to eq('New copyright statement')
    expect(find_field('Default Use and Reproduction statement').value).to eq('New use statement')
    within_fieldset 'Default Collections' do
      expect(page).to have_link('New Testing Collection')
    end
    expect(page).to have_selector('.permissionName', text: 'dpg-staff')
    expect(page).to have_selector('.permissionName', text: 'anyone')

    # This is flaky. The models value is correct, so it something to do with the rendering.
    expect(find_field('Default use license').value).to eq('https://creativecommons.org/licenses/by-nd/3.0/legalcode')

    choose 'Choose a Default Collection'
    select preexisting_collection.externalIdentifier, from: 'apo_form_collection_collection'
    click_button 'Update APO'

    click_on 'Edit APO'

    # Add testing for adding another default collection to this apo.
    within_fieldset 'Default Collections' do
      expect(page).to have_text 'New Testing Collection'
      expect(page).to have_text 'Another type of collection'
    end
  end
end
