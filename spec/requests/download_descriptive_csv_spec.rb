# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download the descriptive CSV' do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model, user_version: user_version_client, version: version_client) }
  let(:user_version_client) { nil }
  let(:version_client) { nil }

  let(:cocina_model) do
    build(:dro_with_metadata, id: druid, source_id: 'sul:91919', title: 'My ETD')
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in build(:user), groups: ['sdr:manager-role']
  end

  it 'returns descriptive csv' do
    get "/items/#{druid}/descriptive.csv"
    expect(response).to have_http_status(:ok)
    csv = CSV.parse(response.body, headers: true)
    expect(csv.headers).to eq ['druid', 'source_id', 'title1.value', 'purl']
    expect(csv[0]['druid']).to eq druid
    expect(csv[0]['source_id']).to eq 'sul:91919'
    expect(csv[0]['title1.value']).to eq 'My ETD'
  end

  context 'with user version specified' do
    let(:cocina_model) do
      build(:dro_with_metadata, id: druid, source_id: 'sul:91919:v2', title: 'My ETD v2', version: user_version.to_i)
    end
    let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: cocina_model) }
    let(:user_version) { '2' }

    it 'returns descriptive csv' do
      get "/items/#{druid}/user_versions/#{user_version}/descriptive.csv"
      expect(response).to have_http_status(:ok)
      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to eq ['druid', 'source_id', 'title1.value', 'purl']
      expect(csv[0]['druid']).to eq druid
      expect(csv[0]['source_id']).to eq 'sul:91919:v2'
      expect(csv[0]['title1.value']).to eq 'My ETD v2'
      expect(user_version_client).to have_received(:find).with(user_version)
    end
  end

  context 'with version specified' do
    let(:cocina_model) do
      build(:dro_with_metadata, id: druid, source_id: 'sul:91919:v2', title: 'My ETD v2', version: version.to_i)
    end
    let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: cocina_model) }
    let(:version) { '2' }

    it 'returns descriptive csv' do
      get "/items/#{druid}/versions/#{version}/descriptive.csv"
      expect(response).to have_http_status(:ok)
      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to eq ['druid', 'source_id', 'title1.value', 'purl']
      expect(csv[0]['druid']).to eq druid
      expect(csv[0]['source_id']).to eq 'sul:91919:v2'
      expect(csv[0]['title1.value']).to eq 'My ETD v2'
      expect(version_client).to have_received(:find).with(version)
    end
  end
end
