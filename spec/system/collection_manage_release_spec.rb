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
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: [], create: true) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find_lite: cocina_model, # NOTE: This should really be a DROLite
                    find: cocina_model,
                    events: events_client,
                    version: version_client,
                    user_version: user_version_client,
                    release_tags: release_tags_client,
                    workflow: workflow_client)
  end
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: true) }
  let(:cocina_model) do
    build(:collection_with_metadata, id: collection_id)
  end
  let(:uber_apo_id) { 'druid:hv992ry2431' }
  let(:collection_id) { 'druid:gg232vv1111' }

  before do
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(MilestoneService).to receive(:milestones_for).and_return({})
    allow(WorkflowService).to receive_messages(workflows_for: [], published?: true)
    solr_conn.add(id: 'druid:gg232vv1111',
                  SolrDocument::FIELD_OBJECT_TYPE => 'collection')
    solr_conn.commit

    sign_in current_user, groups: ['sdr:administrator-role']
  end

  it 'has a manage release button' do
    visit solr_document_path(collection_id)
    expect(page).to have_css 'a', text: 'Manage release'
  end

  it 'sets a tag and starts releaseWF' do
    visit edit_item_manage_release_path(collection_id)

    expect(page).to have_css 'label', text: "Manage release to discovery applications for collection #{collection_id}"
    choose 'This collection and all its members*'
    choose 'Release it'
    click_button 'Submit'

    expect(page).to have_css '.alert', text: "Updated release for #{collection_id}"
    expect(release_tags_client).to have_received(:create) do |args|
      tag = args[:tag]
      expect(tag.to).to eq 'Searchworks'
      expect(tag.who).to eq 'esnowden'
      expect(tag.what).to eq 'self'
      expect(tag.release).to be true
      expect(tag.date).to be_a DateTime
    end
    expect(object_client).to have_received(:workflow).with('releaseWF')
    expect(workflow_client).to have_received(:create).with(version: cocina_model.version)
  end
end
