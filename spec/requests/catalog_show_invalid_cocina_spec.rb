# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Catalog show with invalid HEAD cocina' do
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  let(:druid) { 'druid:hj185xx2222' }
  let(:title) { 'Some Object With a Title' }
  let(:apo_druid) { 'druid:hv992ry2431' }
  let(:solr_doc) do
    {
      id: druid,
      SolrDocument::FIELD_OBJECT_TYPE => 'item',
      ApoConcern::FIELD_APO_ID => [apo_druid],
      display_title_ss: title
    }
  end

  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: [], current: 1) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: []) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    version: version_client,
                    user_version: user_version_client,
                    release_tags: release_tags_client)
  end

  let(:version_service) do
    instance_double(VersionService, open?: false, openable?: false, closeable?: false, open_and_not_assembling?: false)
  end
  let(:state_service) { instance_double(StateService) }

  before do
    solr_conn.add(solr_doc)
    solr_conn.commit

    allow(Repository).to receive(:find_lite).and_raise(Cocina::Models::ValidationError, 'bad cocina')
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(WorkflowService).to receive(:workflows_for).and_return([])
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(StateService).to receive(:new).and_return(state_service)
    allow(Honeybadger).to receive(:notify)

    sign_in create(:user), groups: ['sdr:viewer-role']
  end

  after do
    solr_conn.delete_by_id(druid)
    solr_conn.commit
  end

  it 'returns 200 instead of 500' do
    get "/view/#{druid}"
    expect(response).to have_http_status(:ok)
  end

  it 'renders the warning banner' do
    get "/view/#{druid}"
    expect(response.body).to include('This item is currently not available')
  end

  it 'renders the object title' do
    get "/view/#{druid}"
    expect(response.body).to include(title)
  end

  it 'does not render a "View latest version" link' do
    get "/view/#{druid}"
    expect(response.body).not_to include('View latest version')
  end

  it 'notifies Honeybadger with the druid context' do
    get "/view/#{druid}"
    expect(Honeybadger).to have_received(:notify).with(instance_of(Cocina::Models::ValidationError),
                                                       context: { druid: })
  end
end
