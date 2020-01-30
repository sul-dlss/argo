# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  before do
    obj = instance_double(
      Dor::Collection,
      current_version: '1',
      admin_policy_object: nil,
      datastreams: {},
      catkey: nil,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
    allow(StateService).to receive(:new).and_return(state_service)
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor).to receive(:find).and_return(obj)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:druid) { 'druid:pb873ty1662' }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, release_tags: release_tags_client, events: events_client) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, create: true) }
  let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
  let(:administrative) { instance_double(Cocina::Models::DRO::Administrative, releaseTags: []) }

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
