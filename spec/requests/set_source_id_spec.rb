# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set source id for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:druid) { 'druid:cc243mg0841' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true, reindex: true) }
    let(:cocina_model) { build(:dro_with_metadata, id: druid) }
    let(:version_service) { instance_double(VersionService, open?: true) }

    let(:updated_model) do
      cocina_model.new(
        {
          'identification' => {
            'sourceId' => 'new:source_id'
          }
        }
      )
    end

    before do
      allow(Dor::Services::Client).to receive(:object).and_return(object_client)
      allow(VersionService).to receive(:new).and_return(version_service)
      sign_in user, groups: ['sdr:administrator-role']
    end

    context 'when the source id is valid' do
      it 'updates the source id' do
        post "/items/#{druid}/source_id", params: { new_id: 'new:source_id' }

        expect(object_client).to have_received(:update)
          .with(params: updated_model)
        expect(object_client).to have_received(:reindex)
      end
    end

    context 'when the source id is a duplicate' do
      let(:response) { instance_double(Faraday::Response, status: 409, body: nil, reason_phrase: 'Conflict') }
      let(:conflict_response) { Dor::Services::Client::ConflictResponse.new(response:) }

      before do
        allow(object_client).to receive(:update).and_raise(conflict_response)
      end

      it 'updates the source id' do
        post "/items/#{druid}/source_id", params: { new_id: 'new:source_id' }

        expect { object_client.update }.to raise_error(Dor::Services::Client::ConflictResponse)
        expect(response).to redirect_to solr_document_path(druid)
        expect(flash[:error]).to match 'Source ID could not be updated: Conflict: 409'
      end
    end
  end
end
