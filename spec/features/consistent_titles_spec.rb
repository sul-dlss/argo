# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Consistent titles' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
  end

  let(:title) { 'Slides, IA 11, Geodesic Domes, Double Skin "Growth" House, N.C. State, 1953' }

  it 'catalog index views' do
    visit search_catalog_path f: { objectType_ssim: ['item'] }
    expect(page).to have_css '.index_title', text: '1. ' + title
  end

  describe 'catalog show view' do
    before do
      allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    let(:workflow_client) { instance_double(Dor::Workflow::Client, lifecycle: [], active_lifecycle: []) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative) }
    let(:administrative) { instance_double(Cocina::Models::DRO::Administrative, releaseTags: []) }

    it 'displays the title' do
      visit solr_document_path 'druid:hj185vb7593'
      expect(page).to have_css 'h1', text: title
    end
  end
end
