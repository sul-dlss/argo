# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Collection manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true, open?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find_lite: cocina_model, # NOTE: This should really be a DROLite
                    find: cocina_model,
                    events: events_client,
                    version: version_client,
                    user_version: user_version_client,
                    release_tags: release_tags_client)
  end
  let(:cocina_model) do
    build(:collection_with_metadata, id: collection_id)
  end
  let(:uber_apo_id) { 'druid:hv992ry2431' }
  let(:collection_id) { 'druid:gg232vv1111' }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    solr_conn.add(id: 'druid:gg232vv1111',
                  objectType_ssim: 'collection')
    solr_conn.commit
  end

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
    perform_enqueued_jobs
    reload_page_until_timeout do
      page.has_css?('td', text: 'ReleaseObjectJob') &&
        page.has_css?('td', text: 'Completed')
    end
  end
end
