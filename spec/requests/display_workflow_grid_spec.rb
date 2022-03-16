# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'The workflow grid', type: :request do
  let(:user) { create(:user) }

  context 'as an admin' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'works' do
      get '/report/workflow_grid'
      expect(response).to have_http_status(:ok)
      expect(response.body).to include 'workflow-grid'
    end
  end
end
