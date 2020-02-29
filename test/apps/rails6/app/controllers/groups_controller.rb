class GroupsController < ApplicationController
  def new_group
    @group = Group.find params[:id]
    new_group = @group.dup
    new_group.save!
    redirect_to new_group
  end

  def render_commands
    render text: `#{params.require('name')} some optional text`
    render json: `#{params.require('name')} some optional text`
  end
end
