class HomeController < ApplicationController
  before_filter :filter_it, :only => :test_filter

  def index
  end

  def test_params
    @name = params[:name]
    @indirect = indirect_method(params[:input])
  end

  def test_model
    @name = User.first.name
  end

  def test_cookie
    @name = cookies[:name]
  end

  def test_filter
  end

  def test_file_access
    File.open RAILS_ROOT + "/" + params[:file]
  end

  def test_sql some_var = "hello"
    User.find_by_sql "select * from users where something = '#{some_var}'"
    User.all(:conditions => "status => '#{happy}'")
    @user = User.first(:conditions => "name = '#{params[:name]}'")
  end

  def test_command
    `ls #{params[:file_name]}`

    system params[:user_input]
  end

  def test_eval
    eval params[:dangerous_input]
  end

  def test_redirect
    params[:action] = :index
    redirect_to params
  end

  def test_render
    @some_variable = params[:unsafe_input]
    render :index
  end

  def test_mass_assignment
    User.new(params[:user])
  end

  def test_dynamic_render
    page = params[:page]
    render :file => "/some/path/#{page}"
  end

  def test_load_params
    load params[:file]
    RandomClass.load params[:file]
  end

  def test_redirect_with_url_for
    url = url_for(params)
    redirect_to url 
  end

  def test_sql_nested
    User.humans.alive.find(:all, :conditions => "age > #{params[:age]}")
  end

  def test_another_dynamic_render
    render :action => params[:action]
  end

  # not safe
  def test_send_first_param
    method = params["method"]
    @result = User.send(method.to_sym)
  end

  # not that safe
  def test_send_target
    table = params["table"]
    model = table.classify.constantize
    @result = model.send(:method)
  end

  # safe
  def test_send_second_param
    args = params["args"] || []
    @result = User.send(:method, *args)
  end

  # safe
  def test_send_second_param
    method = params["method"] == 1 ? :method_a : :method_b
    @result = User.send(method, *args)
  end  

  # safe
  def test_send_second_param
    target = params["target"] == 1 ? Account : User
    @result = target.send(:method, *args)
  end    

  private

  def filter_it
    @filtered = params[:evil_input]
  end
end
