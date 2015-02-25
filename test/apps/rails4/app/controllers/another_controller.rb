class AnotherController < ApplicationController
  def overflow
    @test = @test.where.all
  end

  before_filter do
    eval params[:x]
  end

  skip_before_action :set_bad_thing, :except => [:also_use_bad_thing]

  def use_bad_thing
    # This should not warn, because the filter is skipped!
    User.where(@bad_thing)
  end

  def also_use_bad_thing
    `#{@bad_thing}`
  end

  def render_stuff
    user_name = User.current_user.name

    render :text => "Welcome back, #{params[:name]}!}"
    render :text => "Welcome back, #{user_name}!}"
    render :text => params[:q]
    render :text => user_name

    render :inline => "<%= #{params[:name]} %>"
    render :inline => "<%= #{user_name} %>"

    # should not warn
    render :text => CGI.escapeHTML(params[:q])
    render :text => "Welcome back, #{CGI::escapeHTML(params[:name])}!}"
  end

  def use_params_in_regex
    @x = something.match /#{params[:x]}/
  end
end
