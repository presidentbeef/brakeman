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

  def test_sql_with_non_active_record_model
    Noticia.where(params[:bad_stuff])
  end

  def test_http_digest
    authenticate_or_request_with_http_digest do
      something
    end
  end

  def test_render_with_nonsymbol_key
    render x => :y
  end

  def test_mail_to
    @user = User.find(current_user)
  end

  def test_command_injection_locals
    `#{some_command}`
    system("ls #{some_files}")
  end

  def test_mass_assign_with_strong_params
    Bill.create(params[:charge])
  end
end
