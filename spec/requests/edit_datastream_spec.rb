# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Draw the edit datastream form' do
  let(:item) do
    instance_double(Dor::Item, pid: 'druid:bc123df4567', datastreams: { 'descMetadata' => datastream })
  end
  let(:datastream) do
    instance_double(Dor::DescMetadataDS, dsid: 'descMetadata', content: xml)
  end

  let(:xml) do
    <<~XML
      <descMetadata></descMetadata>
    XML
  end

  let(:document) do
    instance_double(SolrDocument,
                    id: 'druid:bc123df4567',
                    object_type: 'item',
                    title: 'My item',
                    released_to: ['Searchworks'])
  end

  let(:user) { create(:user) }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }
  let(:cocina_model) { instance_double(Cocina::Models::DRO, externalIdentifier: 'druid:bc123df4567') }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Dor).to receive(:find).with('druid:bc123df4567').and_return(item)
  end

  context 'for content managers' do
    before do
      sign_in create(:user), groups: ['sdr:administrator-role']

      allow_any_instance_of(Blacklight::Solr::Repository).to receive(:find)
        .with('druid:bc123df4567', {})
        .and_return(instance_double(Blacklight::Solr::Response, documents: [document]))
    end

    it 'authorizes the view' do
      get '/items/druid:bc123df4567/datastreams/descMetadata/edit', xhr: true
      expect(response).to have_http_status(:success)
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
