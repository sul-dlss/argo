# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View Cocina model for user version' do
  let(:user) { create(:user) }

  let(:object_client) { instance_double(Dor::Services::Client::Object, user_version: user_version_client) }
  let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: item) }
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

    it 'return json' do
      get "/items/#{item.externalIdentifier}/user_versions/2.json"
      expect(response).to be_successful
      expect(response.body).to include "\"type\":\"#{Cocina::Models::ObjectType.object}\","
      expect(user_version_client).to have_received(:find).with('2')
    end
  end

  context 'when user is not authorized' do
    before do
      sign_in user
    end

    it 'return unauthorized' do
      get "/items/#{item.externalIdentifier}/user_versions/2.json"
      expect(response).to be_forbidden
    end
  end
end
