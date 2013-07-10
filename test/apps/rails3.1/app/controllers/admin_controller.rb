class AdminController < ApplicationController
  #Examples of skipping important filters with a blacklist instead of whitelist
  skip_before_filter :login_required, :except => :do_admin_stuff
  skip_filter :authenticate_user!, :except => :do_admin_stuff
  skip_before_filter :require_user, :except => [:do_admin_stuff, :do_other_stuff]


  def constantize_some_stuff
    klass = params[:class].constantize
    klass.new.do_bad_things

    params[:class].safe_constantize.new(params[:arg])

    Module.qualified_const_get(params[:const])

    const_get(params[:arg])

    some_method(params[:class]).constantize
  end

  def authenticate_user!
    correct_password = "7001337"

    authenticate_or_request_with_http_basic do |username, password|
      username == "foo" && password == correct_password
    end
  end
end
