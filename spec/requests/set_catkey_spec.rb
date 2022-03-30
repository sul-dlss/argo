# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set catkey' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:dc243mg0841' }

  context 'without manage content access' do
    let(:cocina) { instance_double(Cocina::Models::DRO) }
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
      sign_in user
    end

    it 'returns a 403' do
      patch "/items/#{druid}/catkey", params: { catkey: { catkey: '12345' } }

      expect(response.code).to eq('403')
    end
  end

  context 'when they have manage access' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      sign_in user, groups: ['sdr:administrator-role']
    end

    describe 'display the form' do
      context 'with an item' do
        let(:cocina_model) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.object,
                                 'externalIdentifier' => druid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                 },
                                 'access' => {},
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                                 'structural' => {},
                                 'identification' => {}
                               })
        end

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
        end
      end

      context 'with a collection that has no identification' do
        let(:cocina_model) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.collection,
                                 'externalIdentifier' => druid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                 },
                                 'access' => {},
                                 'identification' => {},
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' }
                               })
        end

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
        end
      end

      context 'with a collection that has identification' do
        let(:cocina_model) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.collection,
                                 'externalIdentifier' => druid, 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                 },
                                 'access' => {},
                                 'identification' => {
                                   'catalogLinks' => [
                                     {
                                       'catalog' => 'symphony',
                                       'catalogRecordId' => '10448742'
                                     }
                                   ]
                                 },
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' }
                               })
        end

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
          expect(response.body).to include '10448742'
        end
      end
    end

    describe 'submitting changes' do
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
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      end

      context 'with an item' do
        let(:cocina_model) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.object,
                                 'externalIdentifier' => druid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                 },
                                 'access' => {},
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                                 'structural' => {},
                                 'identification' => {}
                               })
        end

        it 'updates the catkey, trimming whitespace' do
          patch "/items/#{druid}/catkey", params: { catkey: { catkey: '   12345 ' } }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with a collection that has no identification' do
        let(:cocina_model) do
          Cocina::Models.build({
                                 'label' => 'My ETD',
                                 'version' => 1,
                                 'type' => Cocina::Models::ObjectType.collection,
                                 'externalIdentifier' => druid,
                                 'description' => {
                                   'title' => [{ 'value' => 'My ETD' }],
                                   'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                                 },
                                 'access' => {
                                   'view' => 'world'
                                 },
                                 'identification' => {},
                                 'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' }
                               })
        end

        it 'updates the catkey, trimming whitespace' do
          patch "/items/#{druid}/catkey", params: { catkey: { catkey: '   12345 ' } }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end
    end
  end
end
