# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set governing APO' do
  let(:groups) { ['sdr:administrator-role', 'dlss:dor-admin', 'dlss:developers'] }
  let(:new_apo) do
    Dor::AdminPolicyObject.create(mods_title: 'Stanford University Libraries - Special Collections',
                                  objectType: 'adminPolicy',
                                  pid: 'druid:ww057vk7675') do |apo|
      apo.add_roleplayer('dor-apo-manager', 'sdr:administrator-role')
    end
  end

  let(:identity_md) { instance_double(Nokogiri::XML::Document, xpath: []) }
  let(:item) { FactoryBot.create_for_repository(:item) }

  before do
    ActiveFedora::SolrService.instance.conn.delete_by_query('*:*')
    ActiveFedora::SolrService.commit
    Argo::Indexer.reindex_pid_remotely(new_apo.pid)
    allow(StateService).to receive(:new).and_return(state_service)
    sign_in create(:user), groups: groups
  end

  context 'when modification is not allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: false) }

    it 'returns an error' do
      visit set_governing_apo_ui_item_path item.externalIdentifier
      select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
      click_button 'Update'
      expect(page.status_code).to eq 400
      expect(page).to have_css 'body', text: 'Object cannot be modified in its current state.'
    end

    context 'when the user is not allowed to move the object to the new APO' do
      before do
        allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, Dor::Item, new_apo.pid).and_raise(CanCan::AccessDenied)
      end

      it 'returns an error' do
        visit set_governing_apo_ui_item_path item.externalIdentifier
        select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
        click_button 'Update'
        expect(page.status_code).to eq 403
        expect(page).to have_css 'body', text: 'forbidden'
      end
    end
  end

  context 'when modification is allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    context 'when the user is not allowed to move the object to the new APO' do
      before do
        allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, Dor::Item, new_apo.pid).and_raise(CanCan::AccessDenied)
      end

      it 'returns an error' do
        visit solr_document_path item.externalIdentifier
        click_link 'Set governing APO'

        select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first

        click_button 'Update'
        expect(page.status_code).to eq 403
        expect(page).to have_css 'body', text: 'forbidden'
      end
    end

    it 'is successful' do
      visit solr_document_path item.externalIdentifier
      click_link 'Set governing APO'

      allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, Dor::Item, new_apo.pid)
      select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)
      click_button 'Update'
      expect(page).to have_css 'body', text: 'Governing APO updated!'
      updated = Dor::Services::Client.object(item.externalIdentifier).find
      expect(updated.administrative.hasAdminPolicy).to eq new_apo.pid
    end
  end
end
