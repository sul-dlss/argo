# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set catkey' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:dc243mg0841' }
  let(:catkey_params) do
    { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'true', 'value' => '12345', '_destroy' => '' } } }, 'item_id' => druid }
  end
  let(:delete_catkey_params) do
    { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'true', 'value' => '99999', '_destroy' => '1' },
                                          '1' => { 'refresh' => 'true', 'value' => '45678', '_destroy' => '' } } }, 'item_id' => druid }
  end
  let(:turbo_stream_headers) do
    { 'Accept' => "#{Mime[:turbo_stream]},#{Mime[:html]}",
      'Turbo-Frame' => 'edit_copyright' }
  end
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  context 'without manage content access' do
    let(:cocina) { instance_double(Cocina::Models::DROWithMetadata) }
    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina) }

    before do
      allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
      sign_in user
    end

    it 'returns a 403' do
      patch item_catkey_path(druid), params: catkey_params
      expect(response.code).to eq('403')
    end
  end

  context 'when they have manage access' do
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      sign_in user, groups: ['sdr:manager-role']
    end

    describe 'display the form' do
      context 'with an item' do
        let(:cocina_model) { build(:dro, id: druid) }

        it 'draws the form' do
          get edit_item_catkey_path druid

          expect(response).to be_successful
        end
      end

      context 'with a collection that has no existing catkeys' do
        let(:cocina_model) { build(:collection, id: druid) }

        it 'draws the form' do
          get edit_item_catkey_path druid

          expect(response).to be_successful
        end
      end

      context 'with a collection that has existing catkeys' do
        let(:cocina_model) { build(:collection, id: druid, catkeys: ['10448742']) }

        it 'draws the form' do
          get edit_item_catkey_path druid

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

      context 'with invalid catkey value on an item' do
        let(:invalid_catkey_params) do
          { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'true', 'value' => 'bogus', '_destroy' => '' } } }, 'item_id' => druid }
        end

        it 'does not update the catkey' do
          patch item_catkey_path(druid), params: invalid_catkey_params, headers: turbo_stream_headers

          expect(object_client).not_to have_received(:update)
          expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely).with(druid)
          expect(response.status).to eq 422
        end
      end

      context 'with duplicate catkey values on an item' do
        let(:invalid_catkey_params) do
          { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'false', 'value' => '99999', '_destroy' => '' },
                                                '1' => { 'refresh' => 'true', 'value' => '99999', '_destroy' => '' } } }, 'item_id' => druid }
        end

        it 'does not update the catkey' do
          patch item_catkey_path(druid), params: invalid_catkey_params, headers: turbo_stream_headers

          expect(object_client).not_to have_received(:update)
          expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely).with(druid)
          expect(response.status).to eq 422
        end
      end

      context 'with multiple catkeys set to refresh on an item' do
        let(:invalid_catkey_params) do
          { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'true', 'value' => '12345', '_destroy' => '', 'id' => '12345' },
                                                '1' => { 'refresh' => 'true', 'value' => '45678', '_destroy' => '', 'id' => '45678' } } }, 'item_id' => druid }
        end

        it 'does not update the catkey' do
          patch item_catkey_path(druid), params: invalid_catkey_params, headers: turbo_stream_headers

          expect(object_client).not_to have_received(:update)
          expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely).with(druid)
          expect(response.status).to eq 422
        end
      end

      context 'with an item that has no existing catkeys' do
        let(:mutiple_catkey_params) do
          { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'true', 'value' => '12345', '_destroy' => '' },
                                                '1' => { 'refresh' => 'false', 'value' => '45678', '_destroy' => '' } } }, 'item_id' => druid }
        end
        let(:updated_model_multiple_catkeys) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'symphony', catalogRecordId: '12345', refresh: true },
                               { catalog: 'symphony', catalogRecordId: '45678', refresh: false }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        it 'updates a single catkey' do
          patch item_catkey_path(druid), params: catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end

        it 'updates multiple catkeys' do
          patch item_catkey_path(druid), params: mutiple_catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_multiple_catkeys)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with an item that has a single existing catkey' do
        let(:cocina_model) { build(:dro_with_metadata, id: druid, catkeys: ['99999']) }
        let(:updated_model_deleted_catkey) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: '99999', refresh: false },
                               { catalog: 'symphony', catalogRecordId: '45678', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        it 'updates the catkey' do
          patch item_catkey_path(druid), params: catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end

        it 'deletes the catkey, moving it to previous symphony, and then adds a new one' do
          patch item_catkey_path(druid), params: delete_catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_deleted_catkey)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with an item that has two existing catkeys' do
        let(:cocina_model) { build(:dro_with_metadata, id: druid, catkeys: %w[99999 45678]) }
        let(:update_catkey_params) do
          { catkey: { 'catkeys_attributes' => { '0' => { 'refresh' => 'false', 'value' => '99999', '_destroy' => '' },
                                                '1' => { 'refresh' => 'true', 'value' => '45678', '_destroy' => '' } } }, 'item_id' => druid }
        end
        let(:updated_model_updated_catkeys) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'symphony', catalogRecordId: '99999', refresh: false },
                               { catalog: 'symphony', catalogRecordId: '45678', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        it 'swaps the refresh setting of the catkeys' do
          expect(cocina_model.identification.catalogLinks[0].refresh).to be true # the first catkey is refresh true
          expect(cocina_model.identification.catalogLinks[1].refresh).to be false # the second catkey is refresh false

          patch item_catkey_path(druid), params: update_catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_updated_catkeys) # the updated model swaps the refresh
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with an item that has existing catkeys and existing previous catkeys' do
        let(:cocina_model) { build(:dro_with_metadata, id: druid, catkeys: ['99999']) }
        let(:updated_model_with_previous_catkey) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: '55555', refresh: false },
                               { catalog: 'symphony', catalogRecordId: '12345', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end
        let(:updated_model_with_delete_and_previous_catkey) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous symphony', catalogRecordId: '55555', refresh: false },
                               { catalog: 'previous symphony', catalogRecordId: '99999', refresh: false },
                               { catalog: 'symphony', catalogRecordId: '45678', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        before do
          cocina_model.identification.catalogLinks << Cocina::Models::CatalogLink.new(catalog: 'previous symphony', refresh: false, catalogRecordId: '55555')
        end

        it 'updates the single catkey, preserving previous symphony catkey' do
          patch item_catkey_path(druid), params: catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_with_previous_catkey)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end

        it 'deletes a single catkey, adding it to the existing previous symphony catkey list, and then adds a new one' do
          patch item_catkey_path(druid), params: delete_catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_with_delete_and_previous_catkey)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with a collection that has no existing catkeys' do
        let(:cocina_model) { build(:collection_with_metadata, id: druid, source_id: 'sul:1234') }

        it 'updates the catkey' do
          patch item_catkey_path(druid), params: catkey_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end
    end
  end
end
