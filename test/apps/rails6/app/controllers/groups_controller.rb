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

  def squish_sql
    ActiveRecord::Base.connection.execute "SELECT * FROM #{user_input}".squish
    ActiveRecord::Base.connection.execute "SELECT * FROM #{user_input}".strip
  end

  def show
    template = params[:template]

    # Test file allowlist
    return redirect_to '/groups' unless FILE_LIST.include? template

    render "groups/#{template}"
  end

  def permit_bang_path
    redirect_to groups_path(params.permit!)
  end

  def permit_bang_slice
    params.permit!.slice(:whatever)
  end
end
