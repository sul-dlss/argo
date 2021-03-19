# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  before do
    obj = instance_double(
      Dor::Item,
      current_version: '1',
      admin_policy_object: nil,
      datastreams: {},
      catkey: nil,
      identityMetadata: double(ng_xml: Nokogiri::XML(''))
    )
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor).to receive(:find).and_return(obj)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:metadata_client) { instance_double(Dor::Services::Client::Metadata, datastreams: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find: cocina_model,
                    release_tags: release_tags_client,
                    events: events_client,
                    metadata: metadata_client,
                    version: version_client)
  end
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, create: true) }
  let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
  let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }
  let(:item) do
    FactoryBot.create_for_repository(:item)
  end

  it 'has a manage release button' do
    visit solr_document_path(item.externalIdentifier)
    expect(page).to have_css 'a', text: 'Manage release'
  end

  it 'creates a new bulk action' do
    visit item_manage_release_path(item.externalIdentifier)
    expect(page).to have_css 'label', text: "Manage release to discovery applications for item #{item.externalIdentifier}"
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: 'Processing'
    end
  end
end
