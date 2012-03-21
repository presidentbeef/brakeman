# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :current_user

  def current_user
    return @current_user if @current_user

    user_id = session[:user_id] || cookies[:user_id]

    if user_id
      @current_user = User.find(user_id)
    end
  end

  def require_logged_in
    unless @current_user
      redirect_to '/login', :page => request.path
    end
  end

  def require_admin
    unless @current_user and @current_user.admin?
      render :text => "Access denied"
    end
  end
end
