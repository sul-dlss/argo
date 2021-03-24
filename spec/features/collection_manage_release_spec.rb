# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  before do
    allow(StateService).to receive(:new).and_return(state_service)
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    solr_conn.add(id: 'druid:gg232vv1111',
                  objectType_ssim: 'collection')
    solr_conn.commit
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
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
  let(:cocina_model) do
    instance_double(Cocina::Models::DRO,
                    externalIdentifier: 'druid:999',
                    administrative: administrative,
                    structural: structural,
                    as_json: {})
  end
  let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }
  let(:structural) { instance_double(Cocina::Models::DROStructural, contains: []) }
  let(:collection_id) { 'druid:gg232vv1111' }

  it 'Has a manage release button' do
    visit solr_document_path(collection_id)
    expect(page).to have_css 'a', text: 'Manage release'
  end

  it 'Creates a new bulk action' do
    visit item_manage_release_path(collection_id)
    expect(page).to have_css 'label', text: "Manage release to discovery applications for collection #{collection_id}"
    choose 'This collection and all its members*'
    choose 'Release it'
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    within 'table.table' do
      expect(page).to have_css 'td', text: 'ReleaseObjectJob'
      expect(page).to have_css 'td', text: 'Processing'
    end
  end
end
