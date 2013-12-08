class FriendlyController
  some_helper_thing do
    @user = User.current_user
  end

  def find
    @user = User.friendly.find(params[:id])
    redirect_to @user
  end

  def some_user_thing
    redirect_to @user.url
  end

  def try_and_send
    User.stuff.try(:where, params[:query])
    User.send(:from, params[:table]).all
  end
end
