# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  let(:state_service) { instance_double(StateService, open?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find: item,
                    find_lite: item,
                    events: events_client,
                    version: version_client,
                    release_tags: release_tags_client)
  end
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  before do
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(WorkflowService).to receive(:accessioned?).and_return(true)
  end

  it 'has a manage release button' do
    visit solr_document_path(item.externalIdentifier)
    expect(page).to have_css 'a', text: 'Manage release'
  end

  it 'creates a new bulk action' do
    visit item_manage_release_path(item.externalIdentifier)
    expect(page).to have_css 'label',
                             text: "Manage release to discovery applications for item #{item.externalIdentifier}"
    click_button 'Submit'
    expect(page).to have_css 'h1', text: 'Bulk Actions'
    reload_page_until_timeout(timeout: 3) do
      page.has_css?('td', text: 'ReleaseObjectJob', wait: 1) &&
        page.has_css?('td', text: 'Completed', wait: 1)
    end
  end
end
