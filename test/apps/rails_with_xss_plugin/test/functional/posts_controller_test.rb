require 'test_helper'

class PostsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:posts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create post" do
    assert_difference('Post.count') do
      post :create, :post => { }
    end

    assert_redirected_to post_path(assigns(:post))
  end

  test "should show post" do
    get :show, :id => posts(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => posts(:one).to_param
    assert_response :success
  end

  test "should update post" do
    put :update, :id => posts(:one).to_param, :post => { }
    assert_redirected_to post_path(assigns(:post))
  end

  test "should destroy post" do
    assert_difference('Post.count', -1) do
      delete :destroy, :id => posts(:one).to_param
    end

    assert_redirected_to posts_path
  end
end
