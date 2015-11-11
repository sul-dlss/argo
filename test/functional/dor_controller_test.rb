require 'test_helper'

class DorControllerTest < ActionController::TestCase
  test 'should get query_by_id' do
    get :query_by_id
    assert_response :success
  end

  test 'should get label' do
    get :label
    assert_response :success
  end

end
