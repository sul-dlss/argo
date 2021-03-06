# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release history' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }
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
  let(:all_workflows) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
  let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: all_workflows) }
  let(:workflow_client) do
    instance_double(Dor::Workflow::Client,
                    active_lifecycle: [],
                    lifecycle: [],
                    milestones: {},
                    workflow_routes: workflow_routes)
  end

  context 'for an item' do
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: [tag]) }
    let(:tag) do
      instance_double(Cocina::Models::ReleaseTag,
                      release: 'true',
                      what: 'self',
                      to: 'Searchworks',
                      who: 'pjreed',
                      date: '2017-10-20T15:42:15Z')
    end
    let(:id) { 'druid:qv778ht9999' }

    before do
      solr_conn.add(id: id)
      solr_conn.commit
    end

    it 'items show a release history' do
      visit solr_document_path id
      expect(page).to have_css 'dt', text: 'Releases'
      expect(page).to have_css 'table.table thead tr th', text: 'Release'
      expect(page).to have_css 'tr td', text: /Searchworks/
      expect(page).to have_css 'tr td', text: /pjreed/
    end
  end

  context 'for an adminPolicy' do
    let(:cocina_model) { instance_double(Cocina::Models::AdminPolicy, administrative: administrative, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::AdminPolicyAdministrative) }
    let(:id) { 'druid:qv778ht9999' }

    before do
      solr_conn.add(id: id)
      solr_conn.commit
    end

    it 'does not show release history' do
      visit solr_document_path id
      expect(page).not_to have_css 'dt', text: 'Releases'
    end
  end
end
