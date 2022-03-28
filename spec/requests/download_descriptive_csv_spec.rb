# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Download the descriptive CSV', type: :request do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_client) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'My ETD',
                           'version' => 1,
                           'type' => Cocina::Models::ObjectType.object,
                           'externalIdentifier' => druid,
                           'description' => {
                             'title' => [{ 'value' => 'My ETD' }],
                             'purl' => "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
                           },
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {
                             sourceId: 'sul:91919'
                           }
                         })
  end

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_client)
    sign_in build(:user), groups: ['sdr:administrator-role']
  end

  it 'returns descriptive csv' do
    get "/items/#{druid}/descriptive.csv"
    expect(response).to have_http_status(:ok)
    csv = CSV.parse(response.body, headers: true)
    expect(csv.headers).to eq ['source_id', 'purl', 'title1:value']
    expect(csv[0]['source_id']).to eq 'sul:91919'
    expect(csv[0]['title1:value']).to eq 'My ETD'
  end
end
