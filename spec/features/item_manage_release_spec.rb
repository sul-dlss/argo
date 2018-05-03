require 'spec_helper'

RSpec.feature 'Item manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  before do
    obj = double(
      Dor::Item,
      admin_policy_object: nil,
      allows_modification?: true,
      datastreams: {},
      can_manage_item?: true,
      catkey: nil,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor).to receive(:find).and_return(obj)
  end
  let(:druid) { 'druid:qq613vj0238' }
  scenario 'Has a manage release button' do
    visit solr_document_path(druid)
    expect(page).to have_css 'a', text: 'Manage release'
  end
  scenario 'Creates a new bulk action' do
    visit manage_release_solr_document_path(druid)
    expect(page).to have_css 'label', text: "Manage release to discovery applications for item #{druid}"
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: 'Scheduled Action'
    end
  end
end
