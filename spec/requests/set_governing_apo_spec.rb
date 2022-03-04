# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set APO for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:pid) { 'druid:dc243mg0841' }
    let(:new_apo_id) { 'druid:bc123cd4567' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'description' => {
                               'title' => [{ 'value' => 'My ETD' }],
                               'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                             },
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405', partOfProject: 'EEMS' },
                             'structural' => {},
                             'identification' => {}
                           })
    end
    let(:state_service) { instance_double(StateService, allows_modification?: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
      allow(StateService).to receive(:new).and_return(state_service)
    end

    context 'object modification not allowed' do
      let(:state_service) { instance_double(StateService, allows_modification?: false) }

      it 'redirects with an error' do
        post "/items/#{pid}/set_governing_apo", params: { new_apo_id: new_apo_id }

        expect(response).to redirect_to solr_document_path(pid)
      end
    end

    context 'user not authorized to manage governing APOs' do
      let(:ability) { instance_double(Ability) }

      before do
        allow(Ability).to receive(:new).and_return(ability)
        allow(ability).to receive(:authorize!).with(:manage_governing_apo, cocina_model, new_apo_id).and_raise(CanCan::AccessDenied)
      end

      it 'returns a 403' do
        post "/items/#{pid}/set_governing_apo", params: { new_apo_id: new_apo_id }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).to eq 'forbidden'
      end
    end

    context 'user authorized to manage governing APOs' do
      let(:updated_model) do
        cocina_model.new('administrative' => { 'hasAdminPolicy' => new_apo_id, 'partOfProject' => 'EEMS' })
      end

      it 'updates the governing APO' do
        post "/items/#{pid}/set_governing_apo", params: { new_apo_id: new_apo_id }
        expect(response).to redirect_to(solr_document_path(pid))
        expect(flash[:notice]).to eq 'Governing APO updated!'

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
      end
    end

    context 'when a collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.collection,
                               'externalIdentifier' => pid,
                               'description' => {
                                 'title' => [{ 'value' => 'My ETD' }],
                                 'purl' => "https://purl.stanford.edu/#{pid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                               'identification' => {}
                             })
      end

      let(:updated_model) do
        cocina_model.new('administrative' => { 'hasAdminPolicy' => new_apo_id })
      end

      it 'updates the governing APO' do
        post "/items/#{pid}/set_governing_apo", params: { new_apo_id: new_apo_id }
        expect(response).to redirect_to(solr_document_path(pid))
        expect(flash[:notice]).to eq 'Governing APO updated!'

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
      end
    end
  end
end
