class AdminController < ApplicationController
  def search_users
    # Medium warning because it's probably an admin interface
    User.ransack(params[:q])
  end
end
