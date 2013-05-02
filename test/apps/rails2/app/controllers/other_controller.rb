class OtherController < ApplicationController
  def test_locals
    render :locals => { :input => params[:user_input] }
  end

  def test_object
    render :partial => "account", :object => Account.first
  end

  def test_collection
    users = User.all
    partial = "user"
    render :partial => partial, :collection => users
  end

  def test_iteration
    @users = User.all
  end

  def test_send_file
    send_file params[:file]
  end

  def test_update_attribute
    @user = User.first
    @user.update_attribute(:attr, params[:attr])
  end

  def test_render_template
    @something_bad = params[:bad]

    render :template => 'home/test_render_template'
  end

  def test_render_update
    render :update do |page|
      do_something
    end
  end

  def test_to_i
    @x = params[:x].to_i
    @id = cookies[:id].to_i
  end

  def test_to_sym
    :"#{hello!}"

    x = params[:x].to_sym

    #Checking that the code below does not warn about to_sym again
    call_something_with x

    x.cool_thing?
  end
end
