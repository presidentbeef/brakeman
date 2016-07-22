module UsersHelper
  def bad_helper
    eval(params[:x])
  end
end
