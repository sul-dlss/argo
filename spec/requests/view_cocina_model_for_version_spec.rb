# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'View Cocina model for version' do
  let(:groups) { ['sdr:viewer-role'] }
  let(:item) { FactoryBot.create_for_repository(:persisted_item) }

  before do
    sign_in create(:user), groups: groups
    allow(Repository).to receive(:find_version).and_return(item)
  end

  it 'returns json' do
    get "/items/#{item.externalIdentifier}/version/1.json"
    expect(response).to be_successful
    expect(response.parsed_body).to include(type: Cocina::Models::ObjectType.object)
  end

  context 'with an invalid cocina object' do
    let(:invalid_item) do
      FactoryBot.create_for_repository(:persisted_item).to_h.tap do |hash|
        hash[:description][:title] = [
          {
            parallelValue: [{ value: 'first parallel' }, { value: 'second parallel' }],
            value: 'test object'
          }
        ]
      end
    end
    let(:item) { Cocina::Models.build(invalid_item, validate: false) }

    it 'returns json' do
      get "/items/#{item.externalIdentifier}/version/1.json"
      expect(response).to be_successful
      expect(response.parsed_body).to include(type: Cocina::Models::ObjectType.object)
    end
  end

  context 'when user is not authorized' do
    let(:groups) { [] }

    it 'returns unauthorized' do
      get "/items/#{item.externalIdentifier}/version/1.json"
      expect(response).to be_forbidden
    end
  end
end
