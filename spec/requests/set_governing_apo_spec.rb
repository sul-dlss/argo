# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set APO for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:druid) { 'druid:dc243mg0841' }
    let(:new_apo_id) { 'druid:bc123cd4567' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:cocina_model) { build(:dro, id: druid) }
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'object modification not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'redirects with an error' do
        post "/items/#{druid}/set_governing_apo", params: { new_apo_id: new_apo_id }

        expect(response).to redirect_to solr_document_path(druid)
      end
    end

    context 'user not authorized to manage governing APOs' do
      let(:ability) { instance_double(Ability) }

      before do
        allow(Ability).to receive(:new).and_return(ability)
        allow(ability).to receive(:authorize!).with(:manage_governing_apo, Item, new_apo_id).and_raise(CanCan::AccessDenied)
      end

      it 'returns a 403' do
        post "/items/#{druid}/set_governing_apo", params: { new_apo_id: new_apo_id }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'forbidden'
      end
    end

    context 'user authorized to manage governing APOs' do
      let(:updated_model) do
        cocina_model.new('administrative' => { 'hasAdminPolicy' => new_apo_id })
      end

      it 'updates the governing APO' do
        post "/items/#{druid}/set_governing_apo", params: { new_apo_id: new_apo_id }
        expect(response).to redirect_to(solr_document_path(druid))
        expect(flash[:notice]).to eq 'Governing APO updated!'

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
      end
    end

    context 'when a collection' do
      let(:cocina_model) { build(:collection, id: druid) }
      let(:updated_model) do
        cocina_model.new('administrative' => { 'hasAdminPolicy' => new_apo_id })
      end

      it 'updates the governing APO' do
        post "/items/#{druid}/set_governing_apo", params: { new_apo_id: new_apo_id }
        expect(response).to redirect_to(solr_document_path(druid))
        expect(flash[:notice]).to eq 'Governing APO updated!'

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
      end
    end
  end
end
