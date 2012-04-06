# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def authorized?
    (@user and @current_user == @user[:id]) or (@current_user and @current_user.admin?)
  end
end
