# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remember impersontated groups', type: :request do
  let(:user) { create(:user) }

  context 'as an admin' do
    before do
      sign_in user, groups: ['sdr:administrator-role']
    end

    it 'is able to remember and forget impersonated groups' do
      impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
      post '/auth/remember_impersonated_groups', params: { groups: impersonated_groups_str }
      expect(session[:groups]).to eq(impersonated_groups_str.split(','))

      get '/auth/forget_impersonated_groups'
      expect(session[:groups]).to be_nil
    end
  end

  context 'as an ordinary user' do
    before do
      sign_in user
    end

    it 'is able to forget but not remember impersonated groups' do
      impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
      post '/auth/remember_impersonated_groups', params: { groups: impersonated_groups_str }
      expect(session[:groups]).to be_blank

      get '/auth/forget_impersonated_groups'
      expect(response.status).not_to eq 403
      expect(session[:groups]).to be_blank
    end
  end
end
