# frozen_string_literal: true

require 'rails_helper'

# Feature/view tests for the (old) bulk actions view.
RSpec.describe 'Bulk actions view', js: true do
  let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }

  let(:object_client) do
    instance_double(Dor::Services::Client::Object, publish: true, find: cocina_model, events: events_client)
  end

  let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: admin_md, as_json: {}) }
  let(:admin_md) { instance_double(Cocina::Models::Administrative, releaseTags: nil) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflow_templates: [], lifecycle: [], active_lifecycle: [], milestones: {}) }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  it 'basic page renders ok' do
    visit report_bulk_path

    expect(page).to have_css('h1', text: 'Bulk update operations')
    expect(page).to have_button 'Paste a druid list', disabled: false

    click_button 'Get druids from search'

    within '#pids' do
      # Test that the textarea was populated from a search
      expect(page).to have_content 'druid:zt570tx3016'
    end

    expect(page).to have_button('Refresh MODS', disabled: false)
    expect(page).to have_button('Set source Id', disabled: false)
    expect(page).to have_button('Set object rights', disabled: false)
    expect(page).to have_button('Set content type', disabled: false)
    expect(page).to have_button('Set collection', disabled: false)
    expect(page).to have_button('Apply APO defaults', disabled: false)
    expect(page).to have_button('Add a workflow', disabled: false)
    expect(page).to have_button('Republish', disabled: false)
    expect(page).to have_button('Tags', disabled: false)
    expect(page).to have_button('Purge', disabled: false)

    fill_in 'pids', with: 'druid:zt570tx3016' # just one druid
    click_button 'Republish'
    click_button 'Refresh metadata on PURL'

    expect(page).to have_content 'Done!'
  end
end
