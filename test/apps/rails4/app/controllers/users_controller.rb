class UsersController < ApplicationController
  def test_sql_sanitize
    User.where("age > #{sanitize params[:age]}")
  end

  before_action :set_page

  prepend_before_action :safe_set_page, :only => :test_prepend_before_action
  append_before_action :safe_set_page, :only => :test_append_before_action

  skip_before_action :verify_authenticity_token, :except => [:unsafe_stuff]

  def test_before_action
    render @page
  end

  # Call safe_set_page then set_page
  def test_prepend_before_action
    render @page # should not be safe
  end

  # Call set_page then safe_set_page
  def test_append_before_action
    render @page # should be safe
  end

  def set_page
    @page = params[:page]
  end

  def safe_set_page
    @page = :cool_page_bro
  end

  def redirect_to_model
    # None of these should warn in Rails 4
    if stuff
      redirect_to User.find_by(:name => params[:name])
    elsif other_stuff
      redirect_to User.find_by!(:name => params[:name])
    else
      redirect_to User.where(:stuff => 1).take
    end
  end
end
