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

  def find_by_stuff
    User.find_by "age > #{params[:age_limit]}"
    User.find_by! params[:user_search]
  end

  def symbolize_safe_parameters
    params[:controller].to_sym
    params[:action].intern && params[:controller][/([^\/]+)$/].try(:to_sym)
  end

  def mass_assignment_bypass
    User.create_with(params)  # high warning
    User.create_with(params).create # high warning
    User.create_with(params[:x].permit(:y)) # should not warn, workaround
    something.create_with({}) # should not warn on hash literals
    x.create_with(y(params))  # medium warning
    y.create_with(x)          # weak warning
  end

  def email_finds
    Email.find_by_id! params[:email][:id]
  end

  def case_statement
    @x = case params[:x]
         when :yes
           "yep"
         when :no
           "nope"
         else
           "dunno"
         end
  end

  def open_stuff
    open(params[:url]) # remote code execution warning
    Kernel.open(URI(params[:url])) # file access and RCE warning
    open("#{params[:x]}/something/something") # remote code execution warning
    open("some_path/#{params[:x]}/something/something") # file access warning
  end

  def eval_it
    @x = eval(params[:x])
  end

  def session_key
    session[params[:x]] = params[:y]
    session["blah-#{params[:token]}"] = user.thing
  end

  def hash_some_things
    Digest::MD5.base64digest(params[:password])
    Digest::HMAC.new('that', 'thing', Digest::SHA1)
    Digest::SHA1.new.update(thing)
    Digest::SHA1.digest(current_user.password + current_user.salt)[0,15]

    OpenSSL::Digest::Digest.new('md5')
    OpenSSL::Digest.new("SHA1")
    OpenSSL::Digest::MD5.digest(password)
  end

  def redirector
    redirect_to current_user.place.find(params[:p])
  end

  def more_haml
  end

  def without
    User.new({username: "jjconti", admin: false}, without_protection: true)
  end

  def permit_in_sql
    User.find_by(params.permit(:OMG)) # Don't warn
    User.find_by(params.permit(:OMG)[:OMG]) # Warn
    User.where("#{params.permit(:OMG)}") # Warn
  end

  def exists_with_to_s
    User.exists? params[:x].to_s # Don't warn
  end

  def find_and_create_em
    # These all call find_by(), which we already know is dangerous
    User.find_or_create_by(params[:user])
    User.find_or_create_by!(params[:user])
    User.find_or_initialize_by(params[:user])
  end

  def email_find_by
    Email.find_by id: params[:email][:id]
    Email.find_by! id: params[:email][:id]
  end
end
