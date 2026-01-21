# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Open a version' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:cocina_model) { build(:dro_with_metadata, id: druid) }

  let(:object_service) { instance_double(Dor::Services::Client::Object, version: version_client, find: cocina_model, reindex: true) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, open: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_service)
  end

  context 'when they have update access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'calls dor-services to open a new version' do
      post "/items/#{druid}/version/open", params: { description: 'something' }

      expect(version_client).to have_received(:open).with(description: 'something',
                                                          opening_user_name: user.to_s)
      expect(object_service).to have_received(:reindex)

      expect(response).to redirect_to(solr_document_path(druid))
      expect(flash[:notice]).to eq("#{druid} is open for modification!")
    end
  end

  context 'when cannot be opened' do
    let(:response) { instance_double(Faraday::Response, status: 422, body: '', reason_phrase: 'Cannot open version') }

    before do
      allow(version_client).to receive(:open).and_raise(Dor::Services::Client::UnexpectedResponse.new(response:))
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'calls dor-services to open a new version' do
      post "/items/#{druid}/version/open", params: { description: 'something' }

      expect(version_client).to have_received(:open).with(description: 'something',
                                                          opening_user_name: user.to_s)
      expect(object_service).not_to have_received(:reindex)

      expect(response).to redirect_to(solr_document_path(druid))
      expect(flash[:alert]).to include('Cannot open version')
    end
  end

  context 'without manage item access' do
    before do
      sign_in user
    end

    it 'returns a 403' do
      post "/items/#{druid}/version/open", params: { description: 'something' }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
