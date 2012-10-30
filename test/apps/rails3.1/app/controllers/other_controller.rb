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
end
