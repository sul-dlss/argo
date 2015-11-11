require 'test_helper'

class RegistrationControllerTest < ActionController::TestCase
  test 'should get form' do
    get :form
    assert_response :success
  end

  test 'should get tracksheet' do
    get :tracksheet
    assert_response :success
  end

  test 'should get workflow_list' do
    get :workflow_list
    assert_response :success
  end

end
