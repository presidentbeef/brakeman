class FriendlyController
 
  def find
    @user = User.friendly.find(params[:id])
    redirect_to @user
  end
  
end