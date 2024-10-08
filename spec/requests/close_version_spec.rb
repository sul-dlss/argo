# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Close a version' do
  let(:druid) { 'druid:bc123df4567' }
  let(:user) { create(:user) }
  let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model, reindex: true) }
  let(:cocina_model) { build(:dro_with_metadata, id: druid, version: 2) }

  before do
    allow(Dor::Services::Client).to receive(:object).and_return(object_service)
  end

  context 'when they have update access' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    let(:object_service) do
      instance_double(Dor::Services::Client::Object, version: version_service, find: cocina_model, reindex: true)
    end
    let(:version_service) { instance_double(Dor::Services::Client::ObjectVersion, close: true) }

    it 'calls dor-services to close the version' do
      post "/items/#{druid}/version/close", params: { description: 'something' }
      expect(flash[:notice]).to eq "Version 2 of #{druid} has been closed!"
      expect(version_service).to have_received(:close).with(description: 'something',
                                                            user_name: user.to_s)
    end
  end

  context 'without manage access' do
    before do
      sign_in user, groups: []
    end

    let(:object_service) { instance_double(Dor::Services::Client::Object, find: cocina_model) }

    it 'returns a 403' do
      post "/items/#{druid}/version/close"
      expect(response).to have_http_status(:forbidden)
    end
  end
end
