# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set governing APO' do
  let(:groups) { ['sdr:administrator-role', 'dlss:dor-admin', 'dlss:developers'] }
  let(:new_apo) do
    FactoryBot.create_for_repository(:apo, title: 'Stanford University Libraries - Special Collections',
                                           roles: [{ name: 'dor-apo-manager', members: [{ identifier: 'sdr:administrator-role', type: 'workgroup' }] }])
  end

  let(:identity_md) { instance_double(Nokogiri::XML::Document, xpath: []) }
  let(:state_service) { instance_double(StateService, allows_modification?: true) }

  let(:uber_apo_id) { 'druid:hv992ry2431' }
  let(:item) do
    FactoryBot.create_for_repository(:item, label: 'Foo', source_id: 'sauce:99', admin_policy_id: uber_apo_id, title: 'Test')
  end
  let(:item_id) { item.externalIdentifier }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:solr_conn) { blacklight_config.repository_class.new(blacklight_config).connection }

  before do
    reset_solr

    new_apo
    item

    allow(StateService).to receive(:new).and_return(state_service)
    sign_in create(:user), groups: groups
  end

  context 'when modification is allowed' do
    it 'is successful' do
      visit solr_document_path item_id
      click_link 'Set governing APO'

      select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Governing APO updated!'
      updated = Dor::Services::Client.object(item_id).find
      expect(updated.administrative.hasAdminPolicy).to eq new_apo.externalIdentifier
    end
  end
end
