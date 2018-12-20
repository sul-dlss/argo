# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthController, type: :controller do
  describe 'test impersonation' do
    before do
      sign_in user
    end

    let(:user) { create(:user) }

    context 'as an admin' do
      before do
        allow(controller).to receive(:authorize!).and_return(true)
      end

      it 'is able to remember and forget impersonated groups' do
        impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
        post :remember_impersonated_groups, params: { groups: impersonated_groups_str }
        expect(session[:groups]).to eq(impersonated_groups_str.split(','))

        post :forget_impersonated_groups
        expect(session[:groups]).to eq(nil)
      end
    end

    context 'as an ordinary user' do
      it 'is able to forget but not remember impersonated groups' do
        impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
        post :remember_impersonated_groups, params: { groups: impersonated_groups_str }
        expect(session[:groups]).to be_blank

        post :forget_impersonated_groups
        expect(response.status).not_to eq 403
        expect(session[:groups]).to be_blank
      end
    end
  end
end
