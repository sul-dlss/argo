# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download the structural CSV' do
  let(:user) { create(:user) }
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    allow(Argo::Indexer).to receive(:reindex_druid_remotely)
  end

  context 'when they have manage access' do
    before do
      allow(StructureSerializer).to receive(:as_csv).and_return('one,two,three')
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:cocina_model) do
      build(:dro, id: druid)
    end

    it 'returns the csv' do
      get "/items/#{druid}/structure.csv"

      expect(response).to be_successful
      expect(response.body).to eq 'one,two,three'
    end
  end
end
