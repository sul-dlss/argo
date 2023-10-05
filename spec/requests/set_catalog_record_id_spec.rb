# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set catalog record ID' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:dc243mg0841' }
  let(:catalog_record_id_params) do
    {
      :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'true', 'value' => 'a12345',
                                                                            '_destroy' => '' } } }, 'item_id' => druid
    }
  end
  let(:delete_catalog_record_id_params) do
    { :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'true', 'value' => 'a99999', '_destroy' => '1' },
                                                                   '1' => { 'refresh' => 'true', 'value' => 'a45678',
                                                                            '_destroy' => '' } } }, 'item_id' => druid }
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
      patch item_catalog_record_id_path(druid), params: catalog_record_id_params
      expect(response).to have_http_status(:forbidden)
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
          get edit_item_catalog_record_id_path druid

          expect(response).to be_successful
        end
      end

      context 'with a collection that has no existing catalog_record_ids' do
        let(:cocina_model) { build(:collection, id: druid) }

        it 'draws the form' do
          get edit_item_catalog_record_id_path druid

          expect(response).to be_successful
        end
      end

      context 'with a collection that has existing catalog_record_ids' do
        let(:catalog_record_id) do
          'a10448742'
        end
        let(:cocina_model) do
          build(:collection, id: druid, folio_instance_hrids: [catalog_record_id])
        end

        it 'draws the form' do
          get edit_item_catalog_record_id_path druid

          expect(response).to be_successful
          expect(response.body).to include catalog_record_id
        end
      end
    end

    describe 'submitting changes' do
      let(:updated_model) do
        cocina_model.new(
          {
            identification: {
              catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a12345', refresh: true }],
              sourceId: 'sul:1234'
            }
          }
        )
      end

      before do
        allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      end

      context 'with invalid catalog_record_id value on an item' do
        let(:invalid_catalog_record_id_params) do
          {
            :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'true', 'value' => 'bogus',
                                                                                  '_destroy' => '' } } }, 'item_id' => druid
          }
        end

        it 'does not update the catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: invalid_catalog_record_id_params,
                                                    headers: turbo_stream_headers

          expect(object_client).not_to have_received(:update)
          expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely).with(druid)
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context 'with duplicate catalog_record_id values on an item' do
        let(:invalid_catalog_record_id_params) do
          { :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'false', 'value' => '99999', '_destroy' => '' },
                                                                         '1' => { 'refresh' => 'true', 'value' => '99999',
                                                                                  '_destroy' => '' } } }, 'item_id' => druid }
        end

        it 'does not update the catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: invalid_catalog_record_id_params,
                                                    headers: turbo_stream_headers

          expect(object_client).not_to have_received(:update)
          expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely).with(druid)
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context 'with multiple catalog_record_ids set to refresh on an item' do
        let(:invalid_catalog_record_id_params) do
          { :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'true', 'value' => '12345', '_destroy' => '', 'id' => '12345' },
                                                                         '1' => { 'refresh' => 'true', 'value' => '45678',
                                                                                  '_destroy' => '', 'id' => '45678' } } }, 'item_id' => druid }
        end

        it 'does not update the catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: invalid_catalog_record_id_params,
                                                    headers: turbo_stream_headers

          expect(object_client).not_to have_received(:update)
          expect(Argo::Indexer).not_to have_received(:reindex_druid_remotely).with(druid)
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context 'with an item that has no existing catalog_record_ids' do
        let(:mutiple_catalog_record_id_params) do
          { :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'true', 'value' => 'a12345', '_destroy' => '' },
                                                                         '1' => { 'refresh' => 'false',
                                                                                  'value' => 'a45678', '_destroy' => '' } } }, 'item_id' => druid }
        end
        let(:updated_model_multiple_catalog_record_ids) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a12345', refresh: true },
                               { catalog: 'folio', catalogRecordId: 'a45678', refresh: false }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        it 'updates a single catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end

        it 'updates multiple catalog_record_ids' do
          patch item_catalog_record_id_path(druid), params: mutiple_catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_multiple_catalog_record_ids)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with an item that has a single existing catalog_record_id' do
        let(:cocina_model) do
          build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a99999'])
        end
        let(:updated_model_deleted_catalog_record_id) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous folio', catalogRecordId: 'a99999', refresh: false },
                               { catalog: 'folio', catalogRecordId: 'a45678', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        let(:updated_model_replaced_catalog_record_id) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous folio', catalogRecordId: 'a99999', refresh: false },
                               { catalog: 'folio', catalogRecordId: 'a12345', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        it 'updates the catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_replaced_catalog_record_id)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end

        it 'deletes the catalog_record_id, moving it to previous, and then adds a new one' do
          patch item_catalog_record_id_path(druid), params: delete_catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_deleted_catalog_record_id)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with an item that has two existing catalog_record_ids' do
        let(:cocina_model) do
          build(:dro_with_metadata, id: druid, folio_instance_hrids: %w[a99999 a45678])
        end
        let(:update_catalog_record_id_params) do
          { :catalog_record_id => { 'catalog_record_ids_attributes' => { '0' => { 'refresh' => 'false', 'value' => 'a99999', '_destroy' => '' },
                                                                         '1' => { 'refresh' => 'true', 'value' => 'a45678',
                                                                                  '_destroy' => '' } } }, 'item_id' => druid }
        end
        let(:updated_model_updated_catalog_record_ids) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a45678', refresh: true },
                               { catalog: 'folio', catalogRecordId: 'a99999', refresh: false }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        it 'swaps the refresh setting of the catalog_record_ids' do
          expect(cocina_model.identification.catalogLinks[0].refresh).to be true # the first catalog_record_id is refresh true
          expect(cocina_model.identification.catalogLinks[1].refresh).to be false # the second catalog_record_id is refresh false

          patch item_catalog_record_id_path(druid), params: update_catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_updated_catalog_record_ids) # the updated model swaps the refresh
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with an item that has existing catalog_record_ids and existing previous catalog_record_ids' do
        let(:cocina_model) do
          build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a99999'])
        end
        let(:updated_model_with_previous_catalog_record_id) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous folio', catalogRecordId: 'a55555', refresh: false },
                               { catalog: 'previous folio', catalogRecordId: 'a99999', refresh: false },
                               { catalog: 'folio', catalogRecordId: 'a12345', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end
        let(:updated_model_with_delete_and_previous_catalog_record_id) do
          cocina_model.new(
            {
              identification: {
                catalogLinks: [{ catalog: 'previous folio', catalogRecordId: 'a55555', refresh: false },
                               { catalog: 'previous folio', catalogRecordId: 'a99999', refresh: false },
                               { catalog: 'folio', catalogRecordId: 'a45678', refresh: true }],
                sourceId: 'sul:1234'
              }
            }
          )
        end

        before do
          cocina_model.identification.catalogLinks << Cocina::Models::CatalogLink[catalog: 'previous folio',
                                                                                  refresh: false, catalogRecordId: 'a55555']
        end

        it 'updates the single catalog_record_id, preserving previous catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_with_previous_catalog_record_id)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end

        it 'deletes a single catalog_record_id, adding it to the existing previous catalog_record_id list, and then adds a new one' do
          patch item_catalog_record_id_path(druid), params: delete_catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model_with_delete_and_previous_catalog_record_id)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end

      context 'with a collection that has no existing catalog_record_ids' do
        let(:cocina_model) { build(:collection_with_metadata, id: druid, source_id: 'sul:1234') }

        it 'updates the catalog_record_id' do
          patch item_catalog_record_id_path(druid), params: catalog_record_id_params

          expect(object_client).to have_received(:update)
            .with(params: updated_model)
          expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
        end
      end
    end
  end
end
