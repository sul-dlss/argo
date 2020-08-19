# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set rights for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:pid) { 'druid:cc243mg0841' }
    let(:fedora_obj) { instance_double(Dor::Item, pid: pid, current_version: 1, admin_policy_object: nil) }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:cocina_model) do
      Cocina::Models.build(
        'label' => 'My ETD',
        'version' => 1,
        'type' => Cocina::Models::Vocab.object,
        'externalIdentifier' => pid,
        'access' => { 'access' => 'world' },
        'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
        'structural' => {},
        'identification' => {}
      )
    end

    let(:updated_model) do
      cocina_model.new('access' => { 'access' => 'dark', 'download' => 'none' })
    end

    before do
      allow(Dor).to receive(:find).and_return(fedora_obj)
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'sets the access' do
      post "/items/#{pid}/set_rights", params: { access_form: { rights: 'dark' } }
      expect(response).to redirect_to(solr_document_path(pid))
      expect(object_client).to have_received(:update)
        .with(params: updated_model)
      expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
    end
  end
end
