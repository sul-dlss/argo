require 'test_helper'

class RegistrationControllerTest < ActionController::TestCase
  test "should get bulk" do
    get :bulk
    assert_response :success
  end

  test "should get tracksheet" do
    get :tracksheet
    assert_response :success
  end

  test "should get workflow_list" do
    get :workflow_list
    assert_response :success
  end

end
