# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration catalog_record_id check' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context 'when catalog_record_id found' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_return(true)
    end

    it 'returns true' do
      get '/registration/catalog_record_id?catalog_record_id=123'

      expect(response.body).to eq("true")
      expect(FolioClient).to have_received(:fetch_marc_hash).with(instance_hrid: "123")
    end
  end

  context 'when catalog_record_id not found' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::ResourceNotFound)
    end

    it 'returns false' do
      get '/registration/catalog_record_id?catalog_record_id=123'

      expect(response.body).to eq('false')
    end
  end

  context 'when other error' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::Error)
    end

    it 'returns true' do
      get '/registration/catalog_record_id?catalog_record_id=123'

      expect(response.body).to eq('true')
    end
  end

  context 'when other error and production' do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::Error)
    end

    it 'returns 500' do
      get '/registration/catalog_record_id?catalog_record_id=123'

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
