require 'spec_helper'

describe AuthController, :type => :controller do

  before :each do
    log_in_as_mock_user(subject)
  end

  describe 'test impersonation' do
    it 'should be able to remember and forget impersonated groups' do
      impersonated_groups_str = 'workgroup:dlss:impersonatedgroup1,workgroup:dlss:impersonatedgroup2'
      post :remember_impersonated_groups, {:groups => impersonated_groups_str}
      expect(session[:groups]).to eq(impersonated_groups_str.split(','))

      post :forget_impersonated_groups
      expect(session[:groups]).to eq(nil)
    end
  end
end
