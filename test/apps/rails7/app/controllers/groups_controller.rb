class GroupsController < ApplicationController
  def show
    @group = Group.find(params[:id])
    @user = User.find(params[:id])
  end
end
