# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enable buttons' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    solr_conn.add(id: item_id, objectType_ssim: 'item')
    solr_conn.commit
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:item_id) { 'druid:hj185xx2222' }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:metadata_client) { instance_double(Dor::Services::Client::Metadata, datastreams: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find: cocina_model,
                    events: events_client,
                    metadata: metadata_client,
                    version: version_client)
  end
  let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
  let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }

  it 'buttons are disabled by default that have check_url' do
    visit solr_document_path item_id
    expect(page).to have_css 'a.disabled', text: 'Close Version'
    expect(page).to have_css 'a.disabled', text: 'Open for modification'
    expect(page).to have_css 'a.disabled', text: 'Republish'
  end

  it 'buttons are enabled if their services return true', js: true do
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_close_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_open_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_published).and_return(true)
    visit solr_document_path item_id
    expect(page).not_to have_css 'a.disabled', text: 'Close Version'
    expect(page).not_to have_css 'a.disabled', text: 'Open for modification'
    expect(page).not_to have_css 'a.disabled', text: 'Republish'
  end
end
