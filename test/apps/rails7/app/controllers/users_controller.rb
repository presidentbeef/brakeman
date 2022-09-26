class UsersController < ApplicationController
  def redirect_to_last!
    redirect_to User.last!
  end
end
