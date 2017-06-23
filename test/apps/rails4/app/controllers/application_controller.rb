class ApplicationController < ActionController::API
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  def show_detailed_exceptions?
    true
  end

  def redirect_to_created_model
    if create
      @model = User.create
      @model.save!
      redirect_to @model
    else
      @model = User.create!
      @model.save
      redirect_to @model
    end
  end

  def bypass_ssl_check
    # Should warn on self.verify_mode = OpenSSL::SSL::VERIFY_NONE
    self.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  before_action :set_bad_thing

  def set_bad_thing
    @bad_thing = params[:x]
  end

  def wrong_redirect_only_path
    redirect_to(params.bla.merge(:only_path => true, :display => nil))
  end

  def redirect_only_path_with_unsafe_hash
    redirect_to(params.to_unsafe_hash.merge(:only_path => true, :display => nil))
  end

  def redirect_only_path_with_unsafe_h
    redirect_to(params.to_unsafe_h.merge(:only_path => true, :display => nil))
  end
end
