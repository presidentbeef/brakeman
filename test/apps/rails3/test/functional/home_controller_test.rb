require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get test_params" do
    get :test_params
    assert_response :success
  end

  test "should get test_model" do
    get :test_model
    assert_response :success
  end

  test "should get test_cookie" do
    get :test_cookie
    assert_response :success
  end

  test "should get test_filter" do
    get :test_filter
    assert_response :success
  end

  test "should get test_file_access" do
    get :test_file_access
    assert_response :success
  end

  test "should get test_sql" do
    get :test_sql
    assert_response :success
  end

  test "should get test_command" do
    get :test_command
    assert_response :success
  end

  test "should get test_eval" do
    get :test_eval
    assert_response :success
  end

  test "should get test_redirect" do
    get :test_redirect
    assert_response :success
  end

  test "should get test_render" do
    get :test_render
    assert_response :success
  end

  test "should get test_mass_assignment" do
    get :test_mass_assignment
    assert_response :success
  end

  test "should get test_dynamic_render" do
    get :test_dynamic_render
    assert_response :success
  end

end
