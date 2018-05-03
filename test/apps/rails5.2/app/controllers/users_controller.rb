class UsersController < ApplicationController
  def index
    index_params = params.permit(:name, friend_names: []).to_hash
    User.where(index_params).qualify.all
  end
end
