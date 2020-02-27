# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set governing APO' do
  let(:groups) { ['sdr:administrator-role', 'dlss:dor-admin', 'dlss:developers'] }
  let(:new_apo) { double(Dor::AdminPolicyObject, pid: 'druid:ww057vk7675') }
  let(:identity_md) { instance_double(Nokogiri::XML::Document, xpath: []) }
  let(:obj) do
    instance_double(
      Dor::Item,
      pid: 'druid:kv840rx2720',
      current_version: '1',
      admin_policy_object: new_apo,
      datastreams: {},
      identityMetadata: double(Dor::IdentityMetadataDS, adminPolicy: nil, ng_xml: identity_md)
    )
  end

  before do
    allow(Dor).to receive(:find).with(obj.pid).and_return(obj)
    allow(Dor).to receive(:find).with(new_apo.pid).and_return(new_apo)
    allow(StateService).to receive(:new).and_return(state_service)
    sign_in create(:user), groups: groups
  end

  context 'when modification is not allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: false) }

    it 'returns an error' do
      visit set_governing_apo_ui_item_path 'druid:kv840rx2720'
      select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
      click_button 'Update'
      expect(page.status_code).to eq 403
      expect(page).to have_css 'body', text: 'Object cannot be modified in its current state.'
    end

    context 'when the user is not allowed to move the object to the new APO' do
      before do
        allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, obj, new_apo.pid).and_raise(CanCan::AccessDenied)
      end

      it 'returns an error' do
        visit set_governing_apo_ui_item_path 'druid:kv840rx2720'
        select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first
        click_button 'Update'
        expect(page.status_code).to eq 403
        expect(page).to have_css 'body', text: 'forbidden'
      end
    end
  end

  context 'when modification is allowed' do
    let(:state_service) { instance_double(StateService, allows_modification?: true) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
    let(:cocina_model) { instance_double(Cocina::Models::DRO, administrative: administrative, as_json: {}) }
    let(:administrative) { instance_double(Cocina::Models::DRO::Administrative, releaseTags: []) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    end

    context 'when the user is not allowed to move the object to the new APO' do
      before do
        allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, obj, new_apo.pid).and_raise(CanCan::AccessDenied)
      end

      it 'returns an error' do
        visit solr_document_path 'druid:kv840rx2720'
        click_link 'Set governing APO'

        select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first

        expect(obj).not_to receive(:admin_policy_object=)
        expect(obj).not_to receive(:save)
        expect(Argo::Indexer).not_to receive(:reindex_pid_remotely)

        click_button 'Update'
        expect(page.status_code).to eq 403
        expect(page).to have_css 'body', text: 'forbidden'
      end
    end

    it 'is successful' do
      visit solr_document_path 'druid:kv840rx2720'
      click_link 'Set governing APO'

      allow_any_instance_of(ItemsController).to receive(:authorize!).with(:manage_governing_apo, obj, new_apo.pid)
      select 'Stanford University Libraries - Special Collections', from: 'new_apo_id', match: :first

      expect(obj).to receive(:admin_policy_object=).with(new_apo)
      expect(obj).to receive(:save)
      expect(Argo::Indexer).to receive(:reindex_pid_remotely)

      click_button 'Update'
      expect(page).to have_css 'body', text: 'Governing APO updated!'
    end
  end
end
