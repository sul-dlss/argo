require 'spec_helper'

RSpec.feature 'Set governing APO' do
  let(:groups) { ['sdr:administrator-role', 'dlss:dor-admin', 'dlss:developers'] }
  let(:new_apo) { double(Dor::AdminPolicyObject, pid: 'druid:ww057vk7675') }
  let(:obj) do
    double(
      Dor::Item,
      pid: 'druid:kv840rx2720',
      admin_policy_object: new_apo,
      datastreams: {},
      identityMetadata: double(Dor::IdentityMetadataDS, adminPolicy: nil),
      can_manage_item?: true
    )
  end

  before do
    allow(Dor).to receive(:find).with(obj.pid).and_return(obj)
    allow(Dor).to receive(:find).with(new_apo.pid).and_return(new_apo)
    sign_in create(:user), groups: groups
  end

  scenario 'modification not currently allowed' do
    allow(obj).to receive(:allows_modification?).and_return(false)
    visit set_governing_apo_ui_item_path 'druid:kv840rx2720'
    select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
    click_button 'Update'
    expect(page.status_code).to eq 403
    expect(page).to have_css 'body', text: 'Object cannot be modified in its current state.'
  end

  scenario 'modification not currently allowed, user not allowed to move object to new APO' do
    allow(obj).to receive(:allows_modification?).and_return(false)
    allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, obj, new_apo.pid).and_raise(CanCan::AccessDenied)
    visit set_governing_apo_ui_item_path 'druid:kv840rx2720'
    select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
    click_button 'Update'
    expect(page.status_code).to eq 403
    expect(page).to have_css 'body', text: 'forbidden'
  end

  scenario 'modification allowed, user not allowed to move object to new APO' do
    allow(obj).to receive(:allows_modification?).and_return(true)

    visit solr_document_path 'druid:kv840rx2720'
    click_link 'Set governing APO'

    allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, obj, new_apo.pid).and_raise(CanCan::AccessDenied)
    select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first

    expect(obj).not_to receive(:admin_policy_object=)
    expect(obj).not_to receive(:save)
    expect(obj).not_to receive(:to_solr)
    expect(Dor::SearchService.solr).not_to receive(:add)
    click_button 'Update'
    expect(page.status_code).to eq 403
    expect(page).to have_css 'body', text: 'forbidden'
  end

  scenario 'modification allowed, user allowed to move object to new APO' do
    allow(obj).to receive(:allows_modification?).and_return(true)

    visit solr_document_path 'druid:kv840rx2720'
    click_link 'Set governing APO'

    allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, obj, new_apo.pid)
    select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first

    expect(obj).to receive(:admin_policy_object=).with(new_apo)
    expect(obj).to receive(:save)
    expect(obj).to receive(:to_solr).and_return({})
    expect(Dor::SearchService.solr).to receive(:add).with({})
    click_button 'Update'
    expect(page).to have_css 'body', text: 'Governing APO updated!'
  end
end
