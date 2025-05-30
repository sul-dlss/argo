# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View Cocina model for version' do
  let(:user) { create(:user) }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: item, version: version_client) }
  let(:version_client) { instance_double(Dor::Services::Client::ObjectVersion, find: item) }
  let(:item) do
    FactoryBot.create_for_repository(:persisted_item)
  end

  before do
    allow(Dor::Services::Client).to receive(:object).with(item.externalIdentifier).and_return(object_client)
  end

  context 'when user is authorized' do
    before do
      sign_in user, groups: ['sdr:viewer-role']
    end

    it 'returns json' do
      get "/items/#{item.externalIdentifier}/version/1.json"
      expect(response).to be_successful
      expect(response.body).to include "\"type\":\"#{Cocina::Models::ObjectType.object}\","
      expect(object_client).to have_received(:find)
      expect(version_client).to have_received(:find).with('1')
    end
  end

  context 'when user is not authorized' do
    before do
      sign_in user
    end

    it 'returns unauthorized' do
      get "/items/#{item.externalIdentifier}/version/1.json"
      expect(response).to be_forbidden
    end
  end
end
