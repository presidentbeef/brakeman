class AdminController < ApplicationController
  #Examples of skipping important filters with a blacklist instead of whitelist
  skip_before_filter :login_required, :except => :do_admin_stuff
  skip_filter :authenticate_user!, :except => :do_admin_stuff
  skip_before_filter :require_user, :except => [:do_admin_stuff, :do_other_stuff]
  before_filter -> { @thing = params[:t] }, only: [:use_lambda_filter]

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

  def show_detailed_exceptions?
    yeah_sure_they_are_an_admin_right? current_user
  end

  def make_system_calls
    `#{"blah #{why?}"}`

    # Some command injection of literals
    # which should not raise warnings 
    or_input = if admin
                 "rm -rf"
               else
                 :symbol
               end

    system "cd / && #{or_input}"
    `cd / && #{or_input}`

    system "echo #{1}"
    exec "nmap 192.168.#{1}.1"
    system @thing # no warning
  end

  def use_lambda_filter
    eval @thing
  end

  def authenticate_token!
    authenticate_token_or_basic do |username, password|
      username == "foo"
    end
  end

  def authenticate_token_or_basic(&block)
    authenticate_or_request_with_http_basic(&block)
  end
end
