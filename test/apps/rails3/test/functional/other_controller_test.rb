require 'test_helper'

class OtherControllerTest < ActionController::TestCase
  test "should get test_locals" do
    get :test_locals
    assert_response :success
  end

  test "should get test_object" do
    get :test_object
    assert_response :success
  end

  test "should get test_collection" do
    get :test_collection
    assert_response :success
  end

  test "should get test_iteration" do
    get :test_iteration
    assert_response :success
  end

  test "should get test_send_file" do
    get :test_send_file
    assert_response :success
  end

end
