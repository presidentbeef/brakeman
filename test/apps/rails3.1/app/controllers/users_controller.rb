class UsersController < ApplicationController
  PASSWORD = "superdupersecret"
  
  http_basic_authenticate_with :name => "superduperadmin", :password => PASSWORD, :only => :create

  # GET /users
  # GET /users.json
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user], :without_protection => true)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, :notice => 'User was successfully created.' }
        format.json { render :json => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, :notice => 'User was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :ok }
    end
  end

  def circular_render
  end

  skip_before_filter :verify_authenticity_token, :except => [:create, :edit]

  def redirect_to_new_user
    redirect_to User.new
  end

  def redirect_to_user_url
    redirect_to User.find(1).url
  end

  def redirect_to_user_find_by
    redirect_to User.find_by_name(params[:name])
  end

  def test_file_access_params
    File.unlink(blah(params[:file]))
    Pathname.readlines("blah/#{cookies[:file]}")
    File.delete(params[:file])
    IO.read(User.find_by_name('bob').file_path)
  end

  def redirect_to_user_as_param
    redirect_to blah(User.find(1)) #Don't warn
  end

  def redirect_to_association
    redirect_to User.first.account #Don't warn
  end

  def redirect_to_safe_second_param
    redirect_to :back, :notice => "Go back, #{params[:user]}!" #Don't warn
  end

  def test_simple_helper
    @user = simple_helper
  end

  def test_less_simple_helpers
    assign_ivar
    @input = less_simple_helper
    @other_thing = simple_helper_with_args(params[:x])
  end

  def test_assign_twice
    assign_ivar
  end

  def update_all_users
    #Unsafe
    User.update_all params[:yaysql]
    User.update_all "name = 'Bob'", "name = '#{params[:name]}'"
    User.update_all "old = TRUE", ["name = '#{params[:name]}' AND age > ?", params[:age]]
    User.update_all "old = TRUE", ["name = ? AND age > ?", params[:name], params[:age]], :order => params[:order]

    User.where(:name => params[:name]).update_all(params[:update])
    User.where(:admin => true).update_all("setting = #{params[:setting]}")
    User.where(:name => params[:name]).update_all(["active = ?, age = #{params[:age]}", params[:active]]).limit(1)

    #Safe(ish)
    User.update_all ["name = ?", params[:new_name]], ["name = ?", params[:old_name]]
    User.update_all({:old => true}, ["name = ? AND age > ?", params[:name], params[:age]])
    User.update_all({:admin => true}, { :name => params[:name] }, :limit => params[:limit])
  end

  def test_assign_if
  end

  private

  def simple_helper
    User.find(params[:id])
  end

  def less_simple_helper
    params[:input]
  end

  def simple_helper_with_args arg
    arg
  end

  def assign_ivar
    @some_value = params[:badthing]
  end

  def pluck_something
    User.pluck params[:column]
  end

  include UserMixin

  before_filter :assign_if, :only => :test_assign_if
end
