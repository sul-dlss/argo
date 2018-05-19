require 'spec_helper'

def user_stub
  webauth = double(
    'WebAuth',
    login: 'sunetid',
    attributes: { 'DISPLAYNAME' => 'Example User' },
    privgroup: User::ADMIN_GROUPS.first
  )
  @current_user = User.find_or_create_by_webauth(webauth)
  allow(@current_user).to receive(:is_admin?).and_return(true)
  allow(@current_user).to receive(:is_manager?).and_return(false)
  allow(@current_user).to receive(:roles).and_return([])
  allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(@current_user)
end

describe 'apo', type: :request do
  let(:new_druid) { 'druid:zy987wv6543' }
  after do
    Dor::AdminPolicyObject.find(new_druid).destroy # clean up after ourselves
  end

  before do
    expect(Dor::SuriService).to receive(:mint_id).and_return(new_druid)
    allow(ApoController).to receive(:update_index).with(any_args)
    user_stub
  end

  it 'creates and edits an apo' do
    expect(Dor::Config.workflow.client).to receive(:create_workflow)
    # go to the registration form and fill it in
    visit new_apo_path
    fill_in 'title',     with: 'APO Title'
    fill_in 'copyright', with: 'Copyright statement'
    fill_in 'use',       with: 'Use statement'
    fill_in 'managers',  with: 'dlss:developers'
    fill_in 'viewers',   with: 'sunetid:someone'
    page.select('MODS', from: 'desc_md')
    page.select('Attribution Share Alike 3.0 Unported', from: 'use_license')
    choose('collection_radio', option: 'none')
    click_button 'Register APO'
    # button redirects to catalog view, but return to edit form to check registered values
    visit edit_apo_path(new_druid)
    expect(find_field('title').value).to eq('APO Title')
    expect(find_field('copyright').value).to eq('Copyright statement')
    expect(find_field('use').value).to eq('Use statement')
    expect(find_field('managers').value).to eq('dlss:developers')
    expect(find_field('viewers').value).to eq('sunetid:someone')
    expect(find_field('desc_md').value).to eq('MODS')
    expect(find_field('use_license').value).to eq('by-sa')
    expect(page).to have_no_field('collection')

    # Now change them
    fill_in 'managers',  with: 'dlss:developers dlss:psm-staff'
    fill_in 'viewers',   with: 'sunetid:someone'
    fill_in 'title',     with: 'New APO Title'
    fill_in 'copyright', with: 'New copyright statement'
    fill_in 'use',       with: 'New use statement'
    fill_in 'managers',  with: 'dlss:dpg-staff'
    fill_in 'viewers',   with: 'sunetid:anyone'
    page.select('Attribution No Derivatives 3.0 Unported', from: 'use_license')
    page.select('MODS', from: 'desc_md')
    click_button 'Update APO'
    # button redirects to catalog view, but return to edit form to check registered values
    visit edit_apo_path(new_druid)
    expect(find_field('title').value).to eq('New APO Title')
    expect(find_field('copyright').value).to eq('New copyright statement')
    expect(find_field('use').value).to eq('New use statement')
    expect(find_field('managers').value).to eq('dlss:dpg-staff')
    expect(find_field('viewers').value).to eq('sunetid:anyone')
    expect(find_field('desc_md').value).to eq('MODS')
    expect(find_field('use_license').value).to eq('by-nd')
    expect(page).to have_no_field('collection')
  end
end
