# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set the copyright for an object' do
  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:collection_druid) { 'druid:tv123cg4444' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) do
      Cocina::Models.build({
                             'label' => 'My ETD',
                             'version' => 1,
                             'type' => Cocina::Models::Vocab.object,
                             'externalIdentifier' => pid,
                             'access' => {},
                             'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                             'structural' => {},
                             'identification' => {}
                           })
    end

    let(:updated_model) do
      cocina_model.new(
        {
          'access' => {
            'copyright' => 'in public domain'
          }
        }
      )
    end

    it 'sets the new collection' do
      patch "/items/#{pid}", params: { item: { copyright: 'in public domain' } }

      expect(object_client).to have_received(:update)
        .with(params: updated_model)
      expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
      expect(response.code).to eq('303')
    end
  end
end
