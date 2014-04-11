class UsersController < ApplicationController
  def test_sql_sanitize
    User.where("age > #{sanitize params[:age]}")
  end
end
