# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration marc_record check' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context 'when MARC record found' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_return({ 'fields' => [] })
    end

    it 'returns true' do
      get '/registration/marc_record?catalog_record_id=a12345'

      expect(response.body).to eq('true')
      expect(FolioClient).to have_received(:fetch_marc_hash).with(instance_hrid: 'a12345')
    end
  end

  context 'when MARC record not found' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::ResourceNotFound)
    end

    it 'returns false' do
      get '/registration/marc_record?catalog_record_id=a12345'

      expect(response.body).to eq('false')
    end
  end

  context 'when other error' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::Error)
    end

    it 'returns true' do
      get '/registration/marc_record?catalog_record_id=a12345'

      expect(response.body).to eq('true')
    end
  end

  context 'when other error and production' do
    before do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::Error)
    end

    it 'returns bad_gateway' do
      get '/registration/marc_record?catalog_record_id=a12345'

      expect(response).to have_http_status(:bad_gateway)
    end
  end
end
