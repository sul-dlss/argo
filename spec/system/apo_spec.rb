# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create an apo', :js do
  let(:user) { create(:user) }
  # An Agreement object must exist to populate the dropdown on the form
  let(:agreement) { FactoryBot.create_for_repository(:agreement) }
  let!(:preexisting_collection) do
    FactoryBot.create_for_repository(:persisted_collection,
                                     label: 'Another type of collection label',
                                     title: 'Another type of collection title',
                                     admin_policy_id: agreement.administrative.hasAdminPolicy)
  end

  let(:accession_step_count) { WorkflowClientFactory.build.workflow_template('accessionWF').fetch('processes').size }

  before do
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

    select('Dark', from: 'View access')
    select('Attribution Share Alike 3.0 Unported', from: 'Default use license')
    select('accessionWF', from: 'Default workflows')

    choose 'Create a Collection'
    fill_in 'Collection Title', with: 'New Testing Collection'

    click_button 'Register APO'
    expect(page).to have_text 'created'

    # TODO: This is flaky.  Remove for now until we can figure out why.  5/5/2022
    # page.execute_script 'window.scrollTo(0,250);'
    # expect(page).to have_link 'Test Agreement', href: solr_document_path(agreement.externalIdentifier)
    expect(page).to have_css('.disabled', text: 'Edit APO')
    expect(page).to have_css('.disabled', text: 'Create Collection')

    # Manually complete the accessionWF steps to allow the object to be openable.
    accession_step_count.times do
      # Ensure every step of accessionWF is completed, this will allow us to open a new version.
      click_link 'accessionWF'
      click_button 'Set to completed', match: :first
    end

    click_link 'Unlock to make changes to this object'
    fill_in 'Version description', with: 'Test a change'

    click_button 'Open Version'
    expect(page).to have_content 'open for modification!'

    click_on 'Edit APO'
    expect(page).to have_text 'Add group' # wait for form to render
    expect(find_field('Title').value).to eq('APO Title')
    expect(find_field('View access').value).to eq('dark')
    expect(find_field('Default Copyright statement').value).to eq('Copyright statement')
    expect(find_field('Default Use and Reproduction statement').value).to eq('Use statement')
    expect(page).to have_css('.permissionName', text: 'developers')
    expect(page).to have_css('.permissionName', text: 'someone')
    expect(find_field('Default use license').value).to eq 'https://creativecommons.org/licenses/by-sa/3.0/legalcode'
    within_fieldset 'Default Collections' do
      expect(page).to have_link('New Testing Collection')
    end

    # Change information
    fill_in 'Group name', with: 'dpg-staff'
    click_button 'Add'

    fill_in 'Group name', with: 'anyone'
    select 'View', from: 'permissionRole'
    click_button 'Add'

    fill_in 'Title', with: 'New APO Title'
    select 'Stanford', from: 'View access'
    fill_in 'Default Copyright statement', with: 'New copyright statement'
    fill_in 'Default Use and Reproduction statement', with: 'New use statement'
    select 'Attribution No Derivatives 3.0 Unported', from: 'Default use license'
    click_button 'Update APO'
    expect(page).to have_text 'Actions' # wait for form to render

    click_on 'Edit APO'
    expect(page).to have_text 'Add group' # wait for form to render
    expect(find_field('Title').value).to eq('New APO Title')
    # expect(find_field('View access').value).to eq('stanford') # should work, but flaky and fails often
    expect(find_field('Default Copyright statement').value).to eq('New copyright statement')
    expect(find_field('Default Use and Reproduction statement').value).to eq('New use statement')
    within_fieldset 'Default Collections' do
      expect(page).to have_link('New Testing Collection')
    end
    expect(page).to have_css('.permissionName', text: 'dpg-staff')
    expect(page).to have_css('.permissionName', text: 'anyone')

    # This is flaky. The models value is correct, so it something to do with the rendering.
    expect(find_field('Default use license').value).to eq('https://creativecommons.org/licenses/by-nd/3.0/legalcode')

    choose 'Choose a Default Collection'
    select preexisting_collection.externalIdentifier, from: 'apo_collection_collection'
    click_button 'Update APO'
    expect(page).to have_text 'View in new window' # wait for show page to render
    click_on 'Edit APO'
    expect(page).to have_text 'Add group' # wait for form to render

    # Add another default collection to this apo.
    within_fieldset 'Default Collections' do
      expect(page).to have_text 'New Testing Collection'
      expect(page).to have_text 'Another type of collection title'
    end
  end
end
