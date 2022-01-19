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

  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'My Item',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.book,
                           'externalIdentifier' => item_id,
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  it 'buttons are disabled/invisibile by default that check their value' do
    visit solr_document_path item_id
    expect(page).to have_css 'a[title="Close Version"]', visible: :hidden
    expect(page).to have_css 'a[title="Open for modification"]', visible: :hidden
    expect(page).to have_css 'a.disabled', text: 'Publish'
    expect(page).to have_css 'a.disabled', text: 'Unpublish'
  end

  it 'buttons are enabled if their services return true', js: true do
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_close_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_can_open_version).and_return(true)
    allow_any_instance_of(WorkflowServiceController).to receive(:check_if_published).and_return(true)
    visit solr_document_path item_id
    expect(page).to have_css 'a[title="Close Version"]'
    expect(page).to have_css 'a[title="Open for modification"]'
    expect(page).not_to have_css 'a.disabled', text: 'Republish'
  end
end
