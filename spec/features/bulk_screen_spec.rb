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
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    solr_conn.add(id: 'druid:zt570qh4444',
                  nonhydrus_collection_title_ssim: 'Foo')
    solr_conn.commit
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
      expect(page).to have_content 'druid:zt570qh4444'
    end

    expect(page).to have_button('Set source Id', disabled: false)
    expect(page).to have_button('Set object rights', disabled: false)
    expect(page).to have_button('Set content type', disabled: false)
    expect(page).to have_button('Set collection', disabled: false)

    fill_in 'pids', with: 'druid:zt570qh4444' # just one druid
    click_button 'Set source Id'
    fill_in 'source_ids', with: 'druid:cx969bz4046	test:SOURCE_ID_1234'
    click_button 'Update source ids'

    expect(page).to have_content 'Done!'
  end
end
