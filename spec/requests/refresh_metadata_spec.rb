# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Refresh metadata' do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, refresh_descriptive_metadata_from_ils: true, find: cocina_model) }
  let(:cocina_model) do
    build(:dro_with_metadata, id: druid, folio_instance_hrids: ['a12345'])
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_client)
    allow(VersionService).to receive(:open?).and_return(true)
  end

  context 'when they have manage access' do
    before do
      sign_in create(:user), groups: ['sdr:administrator-role']
    end

    context 'when the object has no catalog_record_id' do
      let(:cocina_model) { build(:dro, id: druid) }

      it 'returns a 400 with an error message' do
        post "/items/#{druid}/refresh_metadata"

        expect(response).to have_http_status(:bad_request)
        expect(response.body).to eq "object must have #{CatalogRecordId.label} to refresh descMetadata"
      end
    end

    context 'when a catalog_record_id is present' do
      it 'redirects with a notice if there is a catalog_record_id' do
        post "/items/#{druid}/refresh_metadata"
        expect(object_client).to have_received(:refresh_descriptive_metadata_from_ils)

        expect(response).to redirect_to solr_document_path(druid)
        expect(flash[:notice]).to eq "Metadata for #{druid} successfully refreshed from #{CatalogRecordId.label}: a12345"
      end
    end

    context "when the object doesn't allow modification" do
      before do
        allow(VersionService).to receive(:open?).and_return(false)
      end

      it 'redirects with an error message' do
        post "/items/#{druid}/refresh_metadata"
        expect(response).to redirect_to solr_document_path(druid)
        expect(flash[:error]).to eq 'Object cannot be modified in its current state.'
      end
    end
  end

  context 'when the user is not allowed to edit desc metadata' do
    before do
      sign_in create(:user), groups: []
    end

    it 'returns a 403 with an error message' do
      post "/items/#{druid}/refresh_metadata"

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to eq 'forbidden'
    end
  end
end
