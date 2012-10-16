module UserControllerMixin
  def mixed_in
    @user = User.find(params[:id])
  end
end
