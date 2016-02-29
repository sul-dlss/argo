require 'spec_helper'

describe AuthController, :type => :controller do

  describe 'test impersonation' do
    context 'as an admin' do
      before :each do
        log_in_as_mock_user(subject, is_webauth_admin?: true)
      end

      it 'should be able to remember and forget impersonated groups' do
        impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
        post :remember_impersonated_groups, {:groups => impersonated_groups_str}
        expect(session[:groups]).to eq(impersonated_groups_str.split(','))

        post :forget_impersonated_groups
        expect(session[:groups]).to eq(nil)
      end
    end

    context 'as an ordinary user' do
      before :each do
        log_in_as_mock_user(subject, is_webauth_admin?: false)
      end

      it 'should be able to remember and forget impersonated groups' do
        impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
        post :remember_impersonated_groups, {:groups => impersonated_groups_str}
        expect(session[:groups]).to be_blank

        post :forget_impersonated_groups
        expect(response.status).to_not eq 403
      end
    end
  end
end
