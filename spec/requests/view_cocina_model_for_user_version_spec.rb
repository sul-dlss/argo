# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View Cocina model for user version' do
  let(:groups) { ['sdr:viewer-role'] }
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }

  # let(:user) { create(:user) }

  # let(:object_client) { instance_double(Dor::Services::Client::Object, user_version: user_version_client) }
  # let(:user_version_client) { instance_double(Dor::Services::Client::UserVersion, find: item) }
  # let(:item) do
  #   FactoryBot.create_for_repository(:persisted_item)
  # end

  before do
    # allow(Dor::Services::Client).to receive(:object).with(item.externalIdentifier).and_return(object_client)
    sign_in create(:user), groups: groups
    allow(Repository).to receive(:find_user_version).and_return(item)
  end

  it 'returns json' do
    get "/items/#{item.externalIdentifier}/public_version/2.json"
    expect(response).to be_successful
    expect(response.parsed_body).to include(type: Cocina::Models::ObjectType.object)
  end

  context 'with an invalid cocina object' do
    let(:item) { Dor::Services::Client::InvalidCocina.new(invalid_item_hash.merge(error_message: 'Foo!')) }
    let(:invalid_item_hash) do
      FactoryBot.create_for_repository(:persisted_item).to_h.tap do |hash|
        hash[:description][:title] = [
          {
            parallelValue: [{ value: 'first parallel' }, { value: 'second parallel' }],
            value: 'test object'
          }
        ]
      end
    end

    it 'returns json' do
      get "/items/#{item.externalIdentifier}/public_version/1.json"
      expect(response).to be_successful
      expect(response.parsed_body).to include(type: Cocina::Models::ObjectType.object, error_message: 'Foo!')
    end
  end

  context 'when user is not authorized' do
    let(:groups) { [] }

    it 'returns unauthorized' do
      get "/items/#{item.externalIdentifier}/public_version/2.json"
      expect(response).to be_forbidden
    end
  end
end
