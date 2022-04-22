# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Set source id for an object' do
  context 'when they have manage access' do
    let(:user) { create(:user) }
    let(:druid) { 'druid:cc243mg0841' }
    let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, update: true) }
    let(:cocina_model) { build(:dro_with_metadata, id: druid) }

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
      allow(Argo::Indexer).to receive(:reindex_druid_remotely)
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'updates the source id' do
      post "/items/#{druid}/source_id", params: { new_id: 'new:source_id' }

      expect(object_client).to have_received(:update)
        .with(params: updated_model)
      expect(Argo::Indexer).to have_received(:reindex_druid_remotely).with(druid)
    end
  end
end
