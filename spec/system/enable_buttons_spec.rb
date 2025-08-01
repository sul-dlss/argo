# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Enable buttons' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    solr_conn.add(id: item_id, objectType_ssim: 'item')
    solr_conn.commit
    allow(StateService).to receive(:new).and_return(state_service)
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(WorkflowService).to receive_messages(accessioned?: true, published?: true, workflows_for: [])
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(MilestoneService).to receive(:milestones_for).and_return({})
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
  let(:item_id) { 'druid:hj185xx2222' }
  let(:state_service) { instance_double(StateService, object_state: :unlock) }
  let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], current: 1) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }
  let(:cocina_model) { build(:dro_lite, id: item_id) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find_lite: cocina_model,
                    events: events_client,
                    version: version_client,
                    user_version: user_version_client,
                    release_tags: release_tags_client)
  end

  it 'buttons are enabled if the state services return unlock', :js do
    visit solr_document_path item_id
    expect(page).to have_css 'a[title="Close Version"]'
  end
end
