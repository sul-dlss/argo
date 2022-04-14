# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download the descriptive CSV', type: :request do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  let(:cocina_model) do
    build(:dro, id: druid, source_id: 'sul:91919', title: 'My ETD')
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in build(:user), groups: ['sdr:administrator-role']
  end

  it 'returns descriptive csv' do
    get "/items/#{druid}/descriptive.csv"
    expect(response).to have_http_status(:ok)
    csv = CSV.parse(response.body, headers: true)
    expect(csv.headers).to eq ['source_id', 'title1.value', 'purl']
    expect(csv[0]['source_id']).to eq 'sul:91919'
    expect(csv[0]['title1.value']).to eq 'My ETD'
  end
end
