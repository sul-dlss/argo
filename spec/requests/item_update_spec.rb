# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set the properties for an object' do
  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_pid_remotely)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'with an item' do
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

      context 'when copyright is passed' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'copyright' => 'in public domain'
              }
            }
          )
        end

        it 'sets the new copyright' do
          patch "/items/#{pid}", params: { item: { copyright: 'in public domain' } }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
          expect(response.code).to eq('303')
        end
      end

      context 'when use_statement is passed' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'useAndReproductionStatement' => 'call before using'
              }
            }
          )
        end

        it 'sets the new use and reproduction statement' do
          patch "/items/#{pid}", params: { item: { use_statement: 'call before using' } }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
          expect(response.code).to eq('303')
        end
      end

      context 'when license is passed' do
        let(:updated_model) do
          cocina_model.new(
            {
              'access' => {
                'license' => 'https://creativecommons.org/licenses/by/4.0/legalcode'
              }
            }
          )
        end

        it 'sets the new license statement' do
          patch "/items/#{pid}", params: { item: { license: 'https://creativecommons.org/licenses/by/4.0/legalcode' } }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
          expect(response.code).to eq('303')
        end
      end
    end

    context 'with a collection' do
      let(:cocina_model) do
        Cocina::Models.build({
                               'label' => 'My ETD',
                               'version' => 1,
                               'type' => Cocina::Models::Vocab.collection,
                               'externalIdentifier' => pid,
                               'access' => {},
                               'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
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

      it 'sets the new copyright' do
        patch "/items/#{pid}", params: { item: { copyright: 'in public domain' } }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(Argo::Indexer).to have_received(:reindex_pid_remotely)
        expect(response.code).to eq('303')
      end
    end
  end
end
