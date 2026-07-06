# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Catalog show with invalid version cocina' do
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

  let(:invalid_cocina) do
    Dor::Services::Client::InvalidCocina.new('externalIdentifier' => druid,
                                             'error_message' => 'bad cocina',
                                             'access' => {
                                               'view' => 'world',
                                               'license' => 'https://creativecommons.org/publicdomain/zero/1.0/legalcode',
                                               'download' => 'world',
                                               'controlledDigitalLending' => false
                                             },
                                             'administrative' => { 'hasAdminPolicy' => apo_druid })
  end

  let(:version1) { Dor::Services::Client::ObjectVersion::Version.new(versionId: 1, message: 'Initial version', cocina: false) }
  let(:version2) { Dor::Services::Client::ObjectVersion::Version.new(versionId: 2, message: 'Changed version', cocina: true) }

  let(:version_client) do
    instance_double(Dor::Services::Client::ObjectVersion, inventory: [version1, version2], current: 2,
                                                          find: invalid_cocina, solr: solr_doc)
  end
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

    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(WorkflowService).to receive(:workflows_for).and_return([])
    allow(MilestoneService).to receive(:milestones_for).and_return({})
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(StateService).to receive(:new).and_return(state_service)

    sign_in create(:user), groups: ['sdr:viewer-role']
  end

  after do
    solr_conn.delete_by_id(druid)
    solr_conn.commit
  end

  it 'returns 200 instead of 500' do
    get "/view/#{druid}?version_id=1"
    expect(response).to have_http_status(:ok)
  end

  it 'renders the warning banner' do
    get "/view/#{druid}?version_id=1"
    expect(response.body).to include('You are viewing an older system version that is no longer valid')
  end

  it 'renders the object title' do
    get "/view/#{druid}?version_id=1"
    expect(response.body).to include(title)
  end
end
