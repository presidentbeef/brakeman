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

  def test_sql_deletes
    User.delete_all("name = #{params[:name]}")
    User.destroy_all("human = #{User.current.humanity}")
  end

  def test_sql_to_s status
    column = "#{product_action_type_key.to_s}_count"
    # Should warn about "product_action_type_key", not "product_action_type_key.to_s"
    Product.where(id: product_id).update_all ["#{column} = #{column} + ?", delta]
    # Should not warn
    Product.where("id = #{id.to_s}")
    # Should warn about "status" not "status.to_s"
    Product.find(:all, :conditions => "product_status_id = " + status.to_s)
    # Show not warn
    Product.find(:all, :conditions => "id = " + Product.first.id.to_s)
  end
end
