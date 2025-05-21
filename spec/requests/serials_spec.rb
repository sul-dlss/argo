# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Serials' do
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true, reindex: true) }
  let(:druid) { 'druid:dc243mg0841' }

  let(:cocina_model) do
    build(:dro_with_metadata, id: druid, label: 'My Serial', title: 'My Serial').new(identification:)
  end
  let(:identification) do
    {
      catalogLinks: [
        { catalog: 'folio', refresh: true, catalogRecordId: 'a6671606', partLabel: '7 samurai', sortKey: '1' }
      ],
      sourceId: 'sul:1234'
    }
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
  end

  context 'when authorized' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
    end

    describe 'GET /items/<item_id>/serials/edit' do
      it 'shows the form' do
        get '/items/druid:kv840xx0000/serials/edit'
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PUT /items/<item_id>/serials' do
      let(:expected) do
        cocina_model.new(description: {
                           title: [
                             { value: 'My Serial' }
                           ],
                           'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                         },
                         identification: {
                           catalogLinks: [
                             { catalog: 'folio', refresh: true, catalogRecordId: 'a6671606', partLabel: '7 samurai', sortKey: '1' }
                           ],
                           sourceId: 'sul:1234'
                         })
      end

      it 'updates the form' do
        put '/items/druid:kv840xx0000/serials', params: { serials: { part_label: '7 samurai', sortKey: '1' } }
        expect(object_client).to have_received(:update).with(params: expected)
        expect(object_client).to have_received(:reindex)

        expect(response).to redirect_to '/view/druid:dc243mg0841'
      end

      context 'when params do not validate' do
        it 'shows the validation errors in the form' do
          put '/items/druid:kv840xx0000/serials', params: { serials: { part_label: '', sort_key: '7 samurai' } }
          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('Part label can&#39;t be blank')
        end
      end
    end
  end
end
