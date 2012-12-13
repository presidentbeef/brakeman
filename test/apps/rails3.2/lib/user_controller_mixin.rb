module UserControllerMixin
  def mixed_in
    @user = User.find(params[:id])
  end

  def [] index
  end
end
