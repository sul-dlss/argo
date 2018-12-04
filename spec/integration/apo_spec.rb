# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'apo', type: :request, js: true do
  let(:user) { create(:user) }
  let(:new_apo_druid) { 'druid:zy987wv6543' }
  let(:new_collection_druid) { 'druid:zy333wv6543' }

  after do
    Dor::AdminPolicyObject.find(new_apo_druid).destroy # clean up after ourselves
    Dor::Collection.find(new_collection_druid).destroy # clean up after ourselves
  end

  before do
    allow(Dor::SuriService).to receive(:mint_id).and_return(new_apo_druid, new_collection_druid)
    allow(ApoController).to receive(:update_index).with(any_args)
    sign_in user, groups: ['sdr:administrator-role']
  end

  it 'creates and edits an apo' do
    expect(Dor::Config.workflow.client).to receive(:create_workflow).twice
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

    page.select('MODS', from: 'desc_md')
    page.select('Attribution Share Alike 3.0 Unported', from: 'use_license')
    choose 'Create a Collection'
    fill_in 'Collection Title', with: 'New Testing Collection'
    click_button 'Register APO'
    expect(page).to have_text 'created'

    click_on 'Edit APO'
    expect(find_field('title').value).to eq('APO Title')
    expect(find_field('copyright').value).to eq('Copyright statement')
    expect(find_field('use').value).to eq('Use statement')
    expect(page).to have_selector('.permissionName', text: 'developers')
    expect(page).to have_selector('.permissionName', text: 'someone')
    expect(find_field('desc_md').value).to eq('MODS')
    expect(find_field('use_license').value).to eq('by-sa')
    expect(page).to have_link('New Testing Collection')

    # Now change them
    fill_in 'Group name', with: 'dpg-staff'
    click_button 'Add'

    fill_in 'Group name', with: 'anyone'
    select 'View', from: 'permissionRole'
    click_button 'Add'

    fill_in 'Title', with: 'New APO Title'
    fill_in 'Default Copyright statement', with: 'New copyright statement'
    fill_in 'Default Use and Reproduction statement', with: 'New use statement'
    page.select('Attribution No Derivatives 3.0 Unported', from: 'use_license')
    page.select('MODS', from: 'desc_md')
    click_button 'Update APO'

    click_on 'Edit APO'
    expect(find_field('title').value).to eq('New APO Title')
    expect(find_field('copyright').value).to eq('New copyright statement')
    expect(find_field('use').value).to eq('New use statement')

    expect(page).to have_selector('.permissionName', text: 'dpg-staff')
    expect(page).to have_selector('.permissionName', text: 'anyone')

    expect(find_field('desc_md').value).to eq('MODS')
    expect(find_field('use_license').value).to eq('by-nd')
  end
end
