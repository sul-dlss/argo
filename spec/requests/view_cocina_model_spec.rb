# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View Cocina model' do
  let(:user) { create(:user) }

  let(:object_client) { instance_double(Dor::Services::Client::Object, find: item) }
  let(:item) do
    FactoryBot.create_for_repository(:item)
  end

  before do
    sign_in user, groups: ['sdr:viewer-role']
    allow(Dor::Services::Client).to receive(:object).with(item.externalIdentifier).and_return(object_client)
  end

  it 'return json' do
    get "/items/#{item.externalIdentifier}.json"
    expect(response).to be_successful
    expect(response.body).to include "\"type\":\"#{Cocina::Models::Vocab.object}\","
  end
end
