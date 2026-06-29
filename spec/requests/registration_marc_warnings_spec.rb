# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration marc_warnings check' do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  context 'when all items have MARC records' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_return({ 'fields' => [] })
    end

    it 'renders an empty turbo-frame' do
      get '/registration/marc_warnings', params: {
        items: [
          { druid: 'yh299zt8993', catalog_record_id: 'a12345' }
        ]
      }

      expect(response.body).to include('<turbo-frame id="marc_warnings">')
      expect(response.body).not_to include('class="alert alert-warning')
      expect(FolioClient).to have_received(:fetch_marc_hash).with(instance_hrid: 'a12345')
    end
  end

  context 'when an item lacks a MARC record' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::ResourceNotFound)
    end

    it 'renders a turbo-frame with the warning alert listing the affected druid' do
      get '/registration/marc_warnings', params: {
        items: [
          { druid: 'yh299zt8993', catalog_record_id: 'a12345' }
        ]
      }

      expect(response.body).to include('<turbo-frame id="marc_warnings">')
      expect(response.body).to include('class="alert alert-warning')
      expect(response.body).to include('The following druids do not have MARC records.')
      expect(response.body).to include('href="/view/druid:yh299zt8993"')
    end
  end

  context 'when a FOLIO error occurs' do
    before do
      allow(FolioClient).to receive(:fetch_marc_hash).and_raise(FolioClient::Error.new('connection failed'))
    end

    it 'renders an empty turbo-frame (assumes MARC exists to avoid false warnings)' do
      get '/registration/marc_warnings', params: {
        items: [
          { druid: 'yh299zt8993', catalog_record_id: 'a12345' }
        ]
      }

      expect(response.body).to include('<turbo-frame id="marc_warnings">')
      expect(response.body).not_to include('class="alert alert-warning')
    end
  end
end
