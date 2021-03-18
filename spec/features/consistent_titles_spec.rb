# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Consistent titles' do
  before do
    ActiveFedora::SolrService.add(id: 'druid:hj185xx2222',
                                  objectType_ssim: 'item',
                                  sw_display_title_tesim: title)
    ActiveFedora::SolrService.commit
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:title) { 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953' }

  it 'catalog index views' do
    visit search_catalog_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css '.index_title a', text: title
  end

  describe 'catalog show view' do
    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    let(:events_client) { instance_double(Dor::Services::Client::Events, list: []) }
    let(:all_workflows) { instance_double(Dor::Workflow::Response::Workflows, workflows: []) }
    let(:workflow_routes) { instance_double(Dor::Workflow::Client::WorkflowRoutes, all_workflows: all_workflows) }
    let(:workflow_client) do
      instance_double(Dor::Workflow::Client,
                      active_lifecycle: [],
                      lifecycle: [],
                      milestones: {},
                      workflow_routes: workflow_routes)
    end
    let(:metadata_client) { instance_double(Dor::Services::Client::Metadata, datastreams: []) }
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, inventory: []) }
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina_model,
                      events: events_client,
                      metadata: metadata_client,
                      version: version_client)
    end
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::Administrative, releaseTags: []) }

    it 'displays the title' do
      visit solr_document_path 'druid:hj185xx2222'
      expect(page).to have_css 'h1', text: title
    end
  end
end
