# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set the properties for a collection' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true, reindex: true) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(VersionService).to receive(:open?).and_return(true)
  end

  context 'when they have manage access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) { build(:collection_with_metadata, id: druid) }

    let(:updated_model) do
      cocina_model.new(
        {
          'access' => {
            'copyright' => 'in public domain'
          }
        }
      )
    end

    it 'sets the new copyright' do
      patch "/collections/#{druid}", params: { collection: { copyright: 'in public domain' } }

      expect(object_client).to have_received(:update)
        .with(params: updated_model)
      expect(object_client).to have_received(:reindex)
      expect(response).to have_http_status(:see_other)
    end
  end
end
