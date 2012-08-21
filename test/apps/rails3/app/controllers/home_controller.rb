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
    User.all(:conditions => "status = '#{happy}'")
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

  def test_mass_assignment_with_hash
    User.new(:name => params[:user][:name])
  end

  def test_dynamic_render
    page = params[:page]
    render :file => "/some/path/#{page}"
  end

  def test_load_params
    load params[:file]
    RandomClass.load params[:file]
  end

  def test_model_build
    current_user = User.new
    current_user.something.something.build(params[:awesome_user])
  end

  def test_only_path
    redirect_to params[:user], :only_path => true
  end

  def test_url_for_only_path
    url = params
    url[:only_path] = false
    redirect_to url_for(url)
  end

  def test_render_a_method_call
    @user = User.find(params['user']).name
    render :test_render
  end

  def test_number_alias
    y + 1 + 2
  end

  private

  def filter_it
    @filtered = params[:evil_input]
  end
end
