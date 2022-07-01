# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Registration source_id check', type: :request do
  let(:user) { create(:user) }
  let(:source_id) { FactoryBot.create_for_repository(:persisted_item).identification.sourceId }

  before do
    sign_in user
  end

  context 'when source_id found' do
    it 'returns true' do
      get "/registration/source_id?source_id=#{source_id}"

      expect(response.body).to eq('true')
    end
  end

  context 'when source_id not found' do
    it 'returns false' do
      get "/registration/source_id?source_id=x#{source_id}"

      expect(response.body).to eq('false')
    end
  end
end
