# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set catkey for an object' do
  let(:user) { create(:user) }
  let(:pid) { 'druid:dc243mg0841' }
  let(:fedora_obj) { instance_double(Dor::Item, pid: pid, current_version: 1, admin_policy_object: nil) }

  before do
    allow(Dor).to receive(:find).and_return(fedora_obj)
  end

  context 'without manage content access' do
    before do
      sign_in user
    end

    it 'returns a 403' do
      post "/items/#{pid}/catkey", params: { new_catkey: '12345' }

      expect(response.code).to eq('403')
    end
  end

  context 'when they have manage access' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'access' => {
                               'access' => 'world'
                             },
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end

    let(:updated_model) do
      cocina_model.new(
        {
          'identification' => {
            'catalogLinks' => [{ catalog: 'symphony', catalogRecordId: '12345' }]
          }
        }
      )
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(Argo::Indexer).to receive(:reindex_pid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'updates the catkey, trimming whitespace' do
      post "/items/#{pid}/catkey", params: { new_catkey: '   12345 ' }

      expect(object_client).to have_received(:update)
        .with(params: updated_model)
      expect(Argo::Indexer).to have_received(:reindex_pid_remotely).with(pid)
    end
  end
end
