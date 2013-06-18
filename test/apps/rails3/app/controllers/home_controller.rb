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

  def test_only_path_wrong
    redirect_to params[:user], :only_path => true #This should still warn
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

  def test_only_path_correct
    params.merge! :only_path => true
    redirect_to params
  end

  def test_content_tag
    @user = User.find(current_user)
  end

  def test_yaml_file_access
    #Should not warn about access, but about remote code execution
    YAML.load "some/path/#{params[:user][:file]}"

    #Should warn
    YAML.parse_file("whatever/" + params[:file_name])
  end

  def test_more_mass_assignment_methods
    #Additional mass assignment methods
    User.first_or_create(params[:user])
    User.first_or_create!(:name => params[:user][:name])
    User.first_or_initialize!(params[:user])
    User.update(params[:id], :alive => false) #No warning
    User.update(1, params[:update])
    User.find(1).assign_attributes(params[:update])
  end

  def test_yaml_load
    YAML.load params[:input]
    YAML.load some_method #No warning
    YAML.load x(cookies[:store])
    YAML.load User.first.bad_stuff
  end

  def test_more_yaml_methods
    YAML.load_documents params[:input]
    YAML.load_stream cookies[:thing]
    YAML.parse_documents "a: #{params[:a]}"
    YAML.parse_stream User.find(1).upload
  end

  def parse_json
    JSON.parse params[:input]
  end

  def mass_assign_slice_only
    Account.new(params.slice(:name, :email))
    Account.new(params.only(:name, email))
  end

  def test_more_ways_to_execute
    Open3.capture2 "ls #{params[:dir]}"
    Open3.capture2e "ls #{params[:dir]}"
    Open3.capture3 "ls #{params[:dir]}"
    Open3.pipeline "sort", "uniq", :in => params[:file] 
    Open3.pipeline_r "sort #{params[:file]}", "uniq"
    Open3.pipeline_rw params[:cmd], "sort -g"
    Open3.pipeline_start *params[:cmds]
    spawn "some_cool_command #{params[:opts]}"
    POSIX::Spawn::spawn params[:cmd]
  end

  private

  def filter_it
    @filtered = params[:evil_input]
  end
end
