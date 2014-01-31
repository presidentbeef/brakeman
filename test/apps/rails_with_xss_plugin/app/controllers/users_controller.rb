class UsersController < ApplicationController
  before_filter :require_logged_in, :only => [:edit, :destroy, :update]

  # GET /users
  # GET /users.xml
  def index
    @users = User.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @evil_input = params[:of_doom]
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    @user.password = nil
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])
    @user.password = `echo #{params[:user][:password]} | shasum`
    @user.user_name.downcase!

    respond_to do |format|
      if User.find(:all, :conditions => { :user_name => params[:user][:user_name] }).empty? and @user.save
        session[:user_id] = @user.id
        format.html { redirect_to(@user, :notice => 'User was successfully created.') }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        @user = User.new
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])
    @user.password = `echo #{params[:user][:password]} | shasum`

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

  def login
    if current_user
      redirect_to params.update(:action => :index)
    else
      render :notice => "Could not login"
    end
  end

  def login_user
    password = `echo #{params[:user][:password]} | shasum`

    $stderr.puts "password: #{password}"

    user = User.find(:first, :conditions => { :user_name => params[:user][:user_name].downcase, :password => password }) 

    if user.nil?
      redirect_to '/login'
    else
      session[:user_id] = user.id

      redirect_to :controller => :posts, :action => :index 
    end
  end

  def logout
    session[:user_id] = nil
    redirect_to :action => :login
  end

  def search
  end

  def results
    @users = User.all(:conditions => "display_name like '%#{params[:query]}%'")
  end

  def to_json

  end

  def delete_them_all
    if User.connection.select_value("SELECT * from users WHERE name='#{params[:name]}'").nil? #should warn
      User.connection.execute("TRUNCATE users") #shouldn't warn
    end
  end
end
