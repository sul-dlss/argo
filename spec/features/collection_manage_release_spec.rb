# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collection manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  before do
    obj = double(
      Dor::Collection,
      admin_policy_object: nil,
      datastreams: {},
      allows_modification?: true,
      can_manage_item?: true,
      catkey: nil,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor).to receive(:find).and_return(obj)
  end

  let(:druid) { 'druid:pb873ty1662' }

  it 'Has a manage release button' do
    visit solr_document_path(druid)
    expect(page).to have_css 'a', text: 'Manage release'
  end
  it 'Creates a new bulk action' do
    visit manage_release_solr_document_path(druid)
    expect(page).to have_css 'label', text: "Manage release to discovery applications for collection #{druid}"
    choose 'This collection and all its members*'
    choose 'Release it'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: 'Scheduled Action'
    end
  end
end
