# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Collection manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }

  around do |example|
    # Don't allow any connections except for solr
    WebMock.disable_net_connect!(allow: 'localhost:8984')
    example.run
    WebMock.allow_net_connect!
  end

  let(:obj) do
    instance_double(
      Dor::Collection,
      pid: druid,
      admin_policy_object: nil,
      datastreams: {},
      allows_modification?: true,
      can_manage_item?: true,
      catkey: nil,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
  end

  before do
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor).to receive(:find).and_return(obj)
  end

  let(:druid) { 'druid:pb873ty1662' }

  context 'on the collection show page' do
    before do
      # Stub the response from the workflow server:
      stub_request(:get, 'http://localhost:3001/dor/objects/druid:pb873ty1662/lifecycle')
        .to_return(body: '')
    end

    it 'Has a manage release button' do
      visit solr_document_path(druid)
      expect(page).to have_css 'a', text: 'Manage release'
    end
  end

  context 'on the manage release page' do
    before do
      # it POSTs to dor-services-app to set a tag
      stub_request(:post, 'http://localhost:3003/v1/objects/druid:pb873ty1662/release_tags')
        .with(body: '{"to":"Searchworks","who":"esnowden","what":"collection","release":true}')

      # it POSTs to dor-services-app to start workflow
      stub_request(:post, 'http://localhost:3003/v1/objects/druid:pb873ty1662/apo_workflows/releaseWF')
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
end
