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
    render(TestComponent.new(params.require('name')))
    render(TestViewComponent.new(params.require('name')))
    render(::TestViewComponent.new(params.require('name')))
    render(TestViewComponentFullyQualifiedAncestor.new(params.require('name')))
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

  def safeish_yaml_load
    YAML.load(params[:yaml_stuff], safe: true)
    YAML.load(params[:yaml_stuff], safe: false) # not safe
    YAML.load(params[:yaml_stuff]) # not safe
  end

  def dynamic_method_invocations
    params[:method].to_sym.to_proc.call(Kernel)
    (params[:klass].to_s).method(params[:method]).(params[:argument])
    Kernel.tap(&params[:method].to_sym)
    User.method("#{User.first.some_method_thing}_stuff")
  end

  def only_for_dev
    if Rails.env.development?
      eval(params[:x]) # should not warn
    end
  end

  def scope_with_custom_sanitization
    ActiveRecord::Base.connection.execute "SELECT * FROM #{sanitize_s(user_input)}"
  end

  def sanitize_s(input)
    input
  end

  def test_rails6_sqli
    User.select("stuff").reselect(params[:columns])
    User.where("x = 1").rewhere("x = #{params[:x]}")
    User.pluck(params[:column]) # Warn in 6.0, not in 6.1
    User.order("name #{params[:direction]}") # Warn in 6.0, not in 6.1
    User.order(:name).reorder(params[:column]) # Warn in 6.0, not in 6.1
  end

  # From https://github.com/presidentbeef/brakeman/issues/1492
  def enum_include_check
    status = "#{params[:status]}"
    if Group.statuses.include? status
      @status = status.to_sym
      @countries = Group.send(@status) # Should not warn
    else
      redirect_to root_path, notice: 'Invalid status'
    end
  end

  def render_phlex_component
    render(TestPhlexComponent.new(params.require('name')))
  end

  def render_view_component_contrib
    render(TestViewComponentContrib.new(params.require('name')))
  end
end
