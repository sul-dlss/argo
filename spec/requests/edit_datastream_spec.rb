# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Draw the edit datastream form' do
  let(:document) do
    instance_double(SolrDocument,
                    id: 'druid:bc123df4567',
                    object_type: 'item',
                    title: 'My item',
                    released_to: ['Searchworks'])
  end

  let(:user) { create(:user) }

  context 'for content managers' do
    let(:object_client) do
      instance_double(Dor::Services::Client::Object,
                      find: cocina_model,
                      metadata: metadata_client)
    end
    let(:metadata_client) { instance_double(Dor::Services::Client::Metadata) }
    let(:cocina_model) { instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:bc123df4567') }

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(metadata_client).to receive(:datastream).with('descMetadata').and_return('<descMetadata></descMetadata>')

      sign_in create(:user), groups: ['sdr:administrator-role']

      allow_any_instance_of(Blacklight::Solr::Repository).to receive(:find)
        .with('druid:bc123df4567', {})
        .and_return(instance_double(Blacklight::Solr::Response, documents: [document]))
    end

    context 'when dsa returns a cocina model' do
      it 'authorizes the view' do
        get '/items/druid:bc123df4567/datastreams/descMetadata/edit', xhr: true
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Update Datastream')
      end
    end

    context 'when dsa returns an UnexpectedResponse' do
      before do
        allow(object_client).to receive(:find).and_raise(Dor::Services::Client::UnexpectedResponse)
      end

      it 'authorizes the view' do
        get '/items/druid:bc123df4567/datastreams/descMetadata/edit', xhr: true
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Update Datastream')
      end
    end
  end

  context 'for unauthorized_user' do
    before do
      sign_in user
    end

    it 'returns not found' do
      expect { get '/items/druid:bc123df4567/datastreams/descMetadata/edit' }
        .to raise_error Blacklight::Exceptions::RecordNotFound
    end
  end
end
