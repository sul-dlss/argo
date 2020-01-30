# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Release history' do
  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Workflow::Client).to receive(:new).and_return(workflow_client)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, active_lifecycle: [], lifecycle: []) }

  context 'for an item' do
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::DRO::Administrative, releaseTags: [tag]) }
    let(:tag) do
      instance_double(Cocina::Models::ReleaseTag,
                      release: 'true',
                      what: 'self',
                      to: 'Searchworks',
                      who: 'pjreed',
                      date: '2017-10-20T15:42:15Z')
    end

    it 'items show a release history' do
      visit solr_document_path 'druid:qq613vj0238'
      expect(page).to have_css 'dt', text: 'Releases'
      expect(page).to have_css 'table.table thead tr th', text: 'Release'
      expect(page).to have_css 'tr td', text: /Searchworks/
      expect(page).to have_css 'tr td', text: /pjreed/
    end
  end

  context 'for an adminPolicy' do
    let(:cocina_model) { instance_double(Cocina::Models::AdminPolicy, administrative: administrative, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::AdminPolicy::Administrative) }

    it 'does not show release history' do
      visit solr_document_path 'druid:fg464dn8891'
      expect(page).not_to have_css 'dt', text: 'Releases'
    end
  end
end
