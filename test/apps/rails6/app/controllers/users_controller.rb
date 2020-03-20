class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  def edit
    render :edit, locals: { some_name.to_sym => 'stuff' }
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def destroy_them_all
    @user.destroy_by(params[:user])
    @user.delete_by(params[:user])
  end

  def dangerous_system_call
    system("bash", "-c", params[:script])
  end

  def dangerous_exec_call
    shell = "zsh"
    exec(shell, SHELL_FLAG, "#{params[:script]} -e ./")
  end
  SHELL_FLAG = "-c"

  def safe_system_call
    system("bash", "-c", "echo", params[:argument])
  end

  def safe_system_call_without_shell_dash_c
    system("echo", "-c", params[:argument])
  end

  def example_redirect_to_request_params
    redirect_to request.params
  end

  def permit_bang
    # Both should warn
    SomeService.new(params: params.permit!).instance_method
    params.permit!.merge({ some: 'hash' })
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name)
    end
end
