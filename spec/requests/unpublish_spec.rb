# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Unpublishing', type: :request do
  let(:druid) { 'druid:bc123df4567' }
  let(:object_service) { instance_double(Dor::Services::Client::Object, unpublish: true, find: cocina_model) }
  let(:cocina_model) do
    Cocina::Models.build({
                           'label' => 'The item',
                           'version' => 1,
                           'type' => Cocina::Models::Vocab.object,
                           'externalIdentifier' => druid,
                           'access' => {},
                           'administrative' => { hasAdminPolicy: 'druid:cg532dg5405' },
                           'structural' => {},
                           'identification' => {}
                         })
  end

  before do
    sign_in create(:user), groups: ['sdr:administrator-role']
    allow(Dor::Services::Client).to receive(:object).with(druid).and_return(object_service)
  end

  it 'unpublishes from PURL' do
    delete "/items/#{druid}/publish"
    expect(object_service).to have_received(:unpublish)
    expect(response).to have_http_status(:found)
  end
end