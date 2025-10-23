# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Item manage release' do
  let(:current_user) { create(:user, sunetid: 'esnowden') }
  let(:version_service) { instance_double(VersionService, open_and_not_assembling?: true) }
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, inventory: []) }
  let(:release_tags_client) { instance_double(Dor::Services::Client::ReleaseTags, list: [], create: nil) }
  let(:workflow_client) { instance_double(Dor::Services::Client::ObjectWorkflow, create: nil) }
  let(:object_client) do
    instance_double(Dor::Services::Client::Object,
                    find: item,
                    find_lite: item,
                    events: events_client,
                    version: version_client,
                    user_version: user_version_client,
                    release_tags: release_tags_client)
  end
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  before do
    sign_in current_user, groups: ['sdr:administrator-role']
    allow(VersionService).to receive(:new).and_return(version_service)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(MilestoneService).to receive(:milestones_for).and_return({})
    allow(WorkflowService).to receive_messages(accessioned?: true, workflows_for: [], published?: false)
  end

  it 'has a manage release button' do
    visit solr_document_path(item.externalIdentifier)
    expect(page).to have_css 'a', text: 'Manage release'
  end

  it 'sets a tag' do
    visit edit_item_manage_release_path(item.externalIdentifier)
    expect(page).to have_css 'label',
                             text: "Manage release to discovery applications for item #{item.externalIdentifier}"
    click_button 'Submit'

    expect(page).to have_css '.alert', text: "Updated release for #{item.externalIdentifier}"
    expect(release_tags_client).to have_received(:create) do |args|
      tag = args[:tag]
      expect(tag.to).to eq 'Searchworks'
      expect(tag.who).to eq 'esnowden'
      expect(tag.what).to eq 'self'
      expect(tag.release).to be true
      expect(tag.date).to be_a DateTime
    end
  end
end
