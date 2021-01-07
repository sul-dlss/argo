# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set the collection for an object' do
  let(:user) { create(:user) }
  let(:pid) { 'druid:bc123df4567' }
  let(:fedora_obj) { instance_double(Dor::Item, pid: pid, current_version: 1, admin_policy_object: nil) }
  let(:collection_druid) { 'druid:tv123cg4444' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

  before do
    allow(Dor).to receive(:find).and_return(fedora_obj)
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'when there are no collections' do
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
            'structural' => {
              'isMemberOf' => [collection_druid]
            }
          }
        )
      end

      it 'sets the collection' do
        post "/items/#{pid}/collection/set", params: { collection: collection_druid, bulk: true }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(response.code).to eq('200')
      end
    end

    context 'when a new collection is not selected' do
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
                               'structural' => { 'isMemberOf' => [collection_druid] },
                               'identification' => {}
                             })
      end

      let(:updated_model) do
        cocina_model.new(
          {
            'structural' => {}
          }
        )
      end

      it 'removes the collection only without adding a new one' do
        post "/items/#{pid}/collection/set", params: { collection: '', bulk: true }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(response.code).to eq('200')
      end
    end

    context 'when a collection is set' do
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
                               'structural' => {
                                 'isMemberOf' => ['druid:xg999dg9393']
                               },
                               'identification' => {}
                             })
      end

      let(:updated_model) do
        cocina_model.new(
          {
            'structural' => {
              'isMemberOf' => [collection_druid]
            }
          }
        )
      end

      it 'sets the new collection' do
        post "/items/#{pid}/collection/set", params: { collection: collection_druid, bulk: true }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(response.code).to eq('200')
      end
    end
  end
end
