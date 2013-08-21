class OtherController < ApplicationController
  def a
    @a = params[:bad]
  end

  def b
    @b = params[:bad]
  end

  def c
    @c = params[:bad]
  end

  def d
    @d = params[:bad]
  end

  def e
    @e = params[:bad]
  end

  def f
    @f = params[:bad]
  end

  def g
    @g = params[:bad]
  end

  def test_partial1
    @a = params[:bad!]
    render :test_partial
  end

  def test_partial2
    @b = params[:badder!]
    render :test_partial
  end

  def test_string_interp
    @user = User.find(current_user)
    @greeting = "Hello, #{greeted += 1; @user.name}!"
  end

  def test_arel_table_access
    User.where(User.arel_table[:id].eq(params[:some_id]))
  end

  def test_draper_redirect
    redirect_to RecordDecorator.decorate(Record.where(:something => params[:access_key]).find(params[:id]))
  end

  def test_model_redirect_in_or
    if something
      user = User.find(params[:something])
    else
      user = User.find(params[:else])
    end

    redirect_to user
  end

  def test_sanitized_medium
    sanitize something
    @css = sanitize_css(some_css)
  end

  def test_deserialization
    CSV.load params[:csv]

    Marshal.load params[:object]

    Marshal.restore User.find(1).cool_stored_thing
  end

  def test_model_in_haml
    @user = User.new
  end
end
