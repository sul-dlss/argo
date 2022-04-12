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
        let(:cocina_model) { build(:dro, id: druid) }

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
        end
      end

      context 'with a collection that has no existing catkeys' do
        let(:cocina_model) { build(:collection, id: druid) }

        it 'draws the form' do
          get "/items/#{druid}/catkey/edit"

          expect(response).to be_successful
        end
      end

      context 'with a collection that has existing catkeys' do
        let(:cocina_model) { build(:collection, id: druid, catkeys: ['10448742']) }

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
            identification: {
              catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12345', refresh: true }],
              sourceId: 'sul:1234'
            }
          }
        )
      end

      before do
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      end

      context 'with an item' do
        let(:cocina_model) { build(:dro, id: druid) }

        it 'updates the catkey, trimming whitespace' do
          patch "/items/#{druid}/catkey", params: { catkey: { catkey: '   12345 ' } }

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with a collection that has no existing catkeys' do
        let(:cocina_model) { build(:collection, id: druid, source_id: 'sul:1234') }

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
