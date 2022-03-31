# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Serials', type: :request do
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
  let(:druid) { 'druid:dc243mg0841' }

  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'My Serial',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druid,
                           'description' => {
                             'title' => [{ 'value' => 'My Serial' }],
                             'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           identification: { sourceId: 'sul:123' }
                         })
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when authorized' do
    before do
      sign_in build(:user), groups: ['sdr:administrator-role']
    end

    describe 'show the form' do
      it 'shows the form' do
        get '/items/druid:kv840xx0000/serials/edit'
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'update the form' do
      let(:expected) do
        Cocina::Models.build({
                               'label' => 'My Serial',
                               'version' => 1,
                               'type' => Cocina::Models::ObjectType.object,
                               'externalIdentifier' => druid,
                               'description' => {
                                 title: [
                                   {
                                     structuredValue: [
                                       { value: 'My Serial', type: 'main title' },
                                       { value: '7', type: 'part number' },
                                       { value: 'samurai', type: 'part name' }
                                     ]
                                   }
                                 ],
                                 'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                               },
                               'access' => {},
                               identification: { sourceId: 'sul:123' },
                               'administrative' => { 'hasAdminPolicy' => 'druid:cg532dg5405' },
                               'structural' => {}
                             })
      end

      it 'updates the form' do
        put '/items/druid:kv840xx0000/serials', params: { serials: { part_number: '7', part_name: 'samurai' } }
        expect(object_client).to have_received(:update).with(params: expected)
        expect(Argo::Indexer).to have_received(:reindex_druid_remotely)

        expect(response).to redirect_to '/view/druid:dc243mg0841'
      end
    end
  end
end
